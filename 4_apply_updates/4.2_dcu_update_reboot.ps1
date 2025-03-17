# Specify possible paths where dcu-cli.exe might be located
$PossibleDcuCliPaths = @(
    "C:\Program Files\Dell\CommandUpdate\dcu-cli.exe",
    "C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe"
)

# Initialize a variable to store the actual path of dcu-cli.exe
$DcuCliPath = $null

# Iterate through each possible path to check if dcu-cli.exe exists
foreach ($path in $PossibleDcuCliPaths) {
    if (Test-Path $path -PathType Leaf) {
        # If dcu-cli.exe is found, set the path and break the loop
        $DcuCliPath = $path
        break
    }
}

# Check if dcu-cli.exe was found
if ($DcuCliPath) {
    # Display a message indicating the detection of Dell Command Update CLI
    Write-Host "Dell Command Update CLI found at $DcuCliPath. Proceeding with operations..."

    try {
        # Start dcu-cli.exe to check if it runs properly
        $DcuCliVersionResult = Start-Process -FilePath $DcuCliPath -ArgumentList "/version" -Wait -NoNewWindow -PassThru
        if ($DcuCliVersionResult.ExitCode -eq 0) {
            Write-Host "`nDell Command Update CLI is running properly."

            $now = Get-Date
            $formattedDateTime = $now.ToString("MM/dd/yyyy [HH:mm:ss]")

            # Define a flag to track whether a reboot is needed
            $rebootNeeded = $false
            $rebootTypes = @()

            # Check for all updates
            $ScanResult = Start-Process -FilePath $DcuCliPath -ArgumentList "/scan" -NoNewWindow -PassThru -Wait -ErrorAction Stop

            # Check exit code for successful scan operation
            switch ($ScanResult.ExitCode) {
                0 {
                    Write-Host "Scan operation completed successfully."
                }
                500 {
                    Write-Host "No updates were found for the system. The system is up to date."
                    Ninja-Property-Set dcuScanLog "No updates found for the system as of - $formattedDateTime"
                    Ninja-Property-Set dcuMostRecentScan "No updates found - $formattedDateTime" --stdin
                    Ninja-Property-Set dcuRebootStatus "No Reboot needed. All applicable updates applied successfully"
                    Exit
                }
                default {
                    Write-Host "Error: Failed to perform scan operation. Exit code: $($ScanResult.ExitCode)"
                    Exit
                }
            }

            # Apply updates
            $ApplyUpdatesResult = Start-Process -FilePath $DcuCliPath -ArgumentList "/applyUpdates -reboot=enable -autoSuspendBitlocker=enable" -NoNewWindow -PassThru -Wait -ErrorAction Stop

            # Check exit code for successful update application
            switch ($ApplyUpdatesResult.ExitCode) {
                0 {
                    # Set Ninja custom fields
                    Ninja-Property-Set dcuScanLog "Updates applied successfully as of - $formattedDateTime"
                    Ninja-Property-Set dcuMostRecentScan $formattedDateTime --stdin
                    Ninja-Property-Set dcuRebootStatus "No reboot needed"
                    
                    Write-Host "Updates applied successfully. No reboot needed."
                }
                1 {
                    # Reboot required from the execution of an operation or pending from a previous operation
                    Write-Host "A reboot is needed... Rebooting now."
                    Ninja-Property-Set dcuRebootStatus "Reboot needed"
                    Ninja-Property-Set dcuScanLog "Updated and rebooted successfully as of - $formattedDateTime"
                    Write-Host "Updates applied successfully. Reboot is needed. Rebooting system..."
                    Write-Host "Rebooting..."
                    Restart-Computer -Force
                }
                5 {
                    # Reboot required from the execution of an operation or pending from a previous operation
                    Write-Host "A reboot is needed... Rebooting now."
                    Ninja-Property-Set dcuRebootStatus "Reboot needed"
                    Ninja-Property-Set dcuScanLog "Updated and rebooted successfully as of - $formattedDateTime"
                    Write-Host "Updates applied successfully. Reboot is needed. Rebooting system..."
                    Write-Host "Rebooting..."
                    Restart-Computer -Force
                }
                1001 {
                    Write-Host "Error: The apply updates operation was canceled."
                }
                1002 {
                    Write-Host "Error: An error occurred while downloading a file during the apply updates operation. Check your network connection and retry the command."
                }
                default {
                    Write-Host "Error: Failed to apply updates. Exit code: $($ApplyUpdatesResult.ExitCode)"
                }
            }
        } else {
            Write-Host "Error: Dell Command Update CLI failed to run properly."
        }
    } catch {
        # Display an error message if an exception occurs during the process
        Write-Host "Error: $_"
    }
} else {
    # Display an error message if Dell Command Update CLI is not found
    Write-Host "Error: Dell Command Update CLI (dcu-cli.exe) not found in the expected paths."
}