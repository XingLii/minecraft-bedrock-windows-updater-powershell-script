<#
    .SYNOPSIS
        Script for automating Minecraft Bedrock Server Updating for Windows
    .DESCRIPTION
        Script which will automatically retrieve the newest version of Bedrock Minecraft.
        Then download it and install the newest version. 
#>

param(
    [String]$WorkingDirectory = (Resolve-Path .\).Path
)


if(!(Test-Path -path "$WorkingDirectory/logs")){
    Write-Verbose -Message "Didn't find the Log folder. Creating it now"
    New-Item -Path "$WorkingDirectory/logs" -ItemType Directory
}


# Setting Log Information 
$Now = get-date
$LogFile = "$WorkingDirectory/logs/" + $Now.ToString("yyyy-MM-dd-HH-mm-ss") + "-minecraf_update.log" # Defining Log name and path
Start-Transcript -Path $LogFile # Starting the LOG
$DebugPreference = 'Continue'
$InformationPreference = 'SilentlyContinue'
$WarningPreference = 'Continue'
$VerbosePreference = 'Continue'

#Setup Folders
if(!(Test-Path -path "$WorkingDirectory/Downloads")){
    Write-Verbose -Message "Didn't find the Download folder. Creating it now"
    New-Item -Path "$WorkingDirectory/Downloads" -ItemType Directory
}
#Create First Time Version File
if(!(Test-Path "$WorkingDirectory/version.txt")){
    Write-Verbose -Message "Didn't find the Version File. Creating it now"
    New-Item "$WorkingDirectory/version.txt" -ItemType File -Force
}


Write-Verbose -Message "Checking for current version installed"
$local_version = Get-Content -Path "$WorkingDirectory/version.txt"

Write-Verbose -Message "Checking for availabe version online"
$request = Invoke-Webrequest -Uri "https://www.minecraft.net/en-us/download/server/bedrock"
$download_link = $request.Links | ? class -match "btn" | ? href -match "bin-win/bedrock" | select -ExpandProperty href


$online_version = $download_link.split("/")[4].split("-")[2].replace(".zip", "")
Write-Verbose -Message "Online version found: $($online_version)"

# If version is different the update the server
if (!($local_version)) {
    
    # Setting up the Server for the First time
    Write-Verbose -Message "First time run of Script"

    Write-verbose -Message "Downloading the new version of the server"
    Invoke-WebRequest -Uri $download_link -OutFile "$WorkingDirectory/Downloads/bedrock-server.zip"
    Write-Verbose -Message "Expanding the folder to the home folder"
    $new_destination = "$WorkingDirectory/bedrock-server" # $WorkingDirectory/bedrock-server
    Expand-Archive -Path "$WorkingDirectory/Downloads/bedrock-server.zip" -DestinationPath $new_destination

    Write-Verbose -Message "Creating a new version.txt file"
    $version_file = "$WorkingDirectory/version.txt"
    New-Item $version_file -ItemType File -Force
    Add-Content -Path $version_file -Value "$($online_version)" -NoNewline

    # Setting the new Server Script to be executable and starting the server
    Write-Verbose -Message "Starting the server for the first Time"
    Start-Process -FilePath "bedrock_server.exe" -WorkingDirectory "$WorkingDirectory/bedrock-server/"  ## Start MC Server


    # Cleaning up downloaded files
    if(Test-Path "$WorkingDirectory/Downloads/bedrock-server.zip"){
        Remove-Item -Path "$WorkingDirectory/Downloads/bedrock-server.zip" -Force
    }
    Write-Verbose -Message "Stop Logging and Exiting the Script"
    Stop-Transcript
    exit


}
elseif ($local_version -eq $online_version) {
    Write-Verbose -Message "Local version and Online version are identical. Exiting script"
    
	if((get-process "bedrock_server.exe" -ea SilentlyContinue) -eq $Null){ 
    
	Write-Verbose -Message "Starting the server as its up to date but not running"
    Start-Process -FilePath "bedrock_server.exe" -WorkingDirectory "$WorkingDirectory/bedrock-server/"  ## Start MC Server
	}

	else{ 
	
	Write-Verbose -Message "Server is running and Up to date. Nothing to do. Exiting"
	exit
	}
}
else {
    # Stopping the Minecraft server
    Write-Verbose -Message "There are difference in Online and Local versions"
    Write-Verbose -Message "Stopping the Minecraft service"
    Get-Process | ? {$_.ProcessName -eq "bedrock_server.exe"} | Stop-Process -Force  # Fore Stop Minecraft Server

    start-sleep -s 2

    # Backup the Minecraft server
    Write-Verbose -Message "Initiating server backup"
    if(!(Test-Path -path "$WorkingDirectory/backup")){
        Write-Verbose -Message "Didn't find the backup folder. Creating it now"
        New-Item -Path "$WorkingDirectory/backup" -ItemType Directory
    }
    Write-Verbose -Message "Copying the current server into the backup folder"
    $backup_folder = "$WorkingDirectory/backup/bedrock-server-$($local_version)"
    Copy-Item -Path "$WorkingDirectory/bedrock-server" -Destination $backup_folder -recurse

    Start-Sleep -s 5

    # Removing old server files from $WorkingDirectory
    Write-Warning -Message "Removing the current version of the server!"
    Remove-Item -Path "$WorkingDirectory/bedrock-server" -Recurse -Force

    
    # Downloading and Extracting the new version of Minecraft
    Write-verbose -Message "Downloading the new version of the server"
    Invoke-WebRequest -Uri $download_link -OutFile "$WorkingDirectory/Downloads/bedrock-server.zip"
    Write-Verbose -Message "Expanding the folder to the home folder"
    $new_destination = "$WorkingDirectory/bedrock-server" # $WorkingDirectory/bedrock-server
    Expand-Archive -Path "$WorkingDirectory/Downloads/bedrock-server.zip" -DestinationPath $new_destination


    # Copying old Configurations files to the new server
    Write-Verbose -Message "Copying world files into new server"
    Copy-Item "$backup_folder/worlds" -Destination $new_destination -Recurse -Force
    Write-Verbose -Message "Copying permissions file into new server"
    Copy-Item "$backup_folder/permissions.json" -Destination $new_destination -Force
    Write-Verbose -Message "Copying server properties file into new server"
    Copy-Item "$backup_folder/server.properties" -Destination $new_destination -Force
    Write-Verbose -Message "Copying allowlist file into new server"
    Copy-Item "$backup_folder/allowlist.json" -Destination $new_destination -Force
    
    # Will be not used after 1.18.11.01 - please migrate to new allowlist.json
    #Write-Verbose -Message "Copying whitelist file into new server"
    #Copy-Item "$backup_folder/whitelist.json" -Destination $new_destination -Force
    
    Write-Verbose -Message "Copying Resource Packs"
    Copy-Item "$backup_folder/resource_packs" -Destination $new_destination -Recurse -Force


    # Creating new Version text file
    Write-Verbose -Message "Creating a new version.txt file"
    $version_file = "$WorkingDirectory/version.txt"
    New-Item $version_file -ItemType File -Force
    Add-Content -Path $version_file -Value "$($online_version)" -NoNewline


    # Compressing the backup server folder
    Write-Verbose -Message "Compressing the backed up server version to conserve space"
    Compress-Archive -Path $backup_folder -DestinationPath "$($backup_folder).zip"


    # Removing the old uncompressed server files
    Write-Verbose -Message "Remove uncompressed version of backup server"
    if(Test-Path "$($backup_folder).zip"){
        Remove-Item -Path $backup_folder -Recurse -Force
    }


    # Setting the new Server Script to be executable and starting the server
    Write-Verbose -Message "Starting the server again"
    Start-Process -FilePath "bedrock_server.exe" -WorkingDirectory "$WorkingDirectory/bedrock-server/"  ## Start MC Server


    # Cleaning up downloaded files
    if(Test-Path "$WorkingDirectory/Downloads/bedrock-server.zip"){
        Remove-Item -Path "$WorkingDirectory/Downloads/bedrock-server.zip" -Force
    }
}

Write-Verbose -Message "Stop Logging and Exiting the Script"
# Stopping the log file
Stop-Transcript