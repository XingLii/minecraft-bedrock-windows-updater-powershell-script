# minecraft-bedrock-windows-updater-powershell-script
 PS Script for Updating a Bedrock Server



How it works:

1. Create a folder
2. Create in this folder a PS1 File with this Script Code in it. 
3. Run this script
    3.1 It will automaticly check if its will be the first run and download the latest version
    3.2 It will create a Log file to check whats going on
4. Create a Windows Task to run it how often you like to
    4.1 Each time the script will run, it will check what version is online + what version is on your Windows (version.txt check)
        - If the Version matches, nothing will be updated, it will check only, if the server is running, if not, it will start it.
        - If the Version doesnt matches, it will shutdown the server and does a Backup from following the Server.
        - After this it will download the newes Version, delete the old version and copying the old Config back into the new Version
        - Following files/folders will be recovered:
            - worlds
            - permissions.json
            - server.properties
            - whitelist.json
            - resource_packs
        - After this step it will zip the old Backup to save storage. It will be saved into the Backup folder.
        - Next it will update the version.txt with the lates version to have it up to date for the next check
        - Delete the downloaded version to save storage & Removing the old uncompressed server files
        - Start the Server again