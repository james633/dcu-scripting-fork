# Function to download and install Dell Command Update using the installer from Dell's website
function Install-DellCommandUpdateUsingInstaller {
# URL of the Dell Command Update installer
    $installerUrl = "https://downloads.dell.com/FOLDER11563484M/1/Dell-Command-Update-Windows-Universal-Application_P83K5_WIN_5.3.0_A00.EXE"
    $ExpectedHash = "C0E844E1CDCA160C21EEB3F8D30813D337E0E3AEB27B82ACA201811DF77A5D5F"
# Path where the installer will be downloaded
    $installerPath = "$env:TEMP\DCU_Setup.exe"
    try {
# Download the installer
        #Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -ErrorAction Stop
        Start-BitsTransfer -Source $installerUrl -Destination $installerPath

#CHECK THE HASH OF THE DOWNLOAD, only continue if it matches expected hash.
        $FileHash = Get-FileHash $installerPath | Select -Expand Hash
        if ($FileHash -ne $ExpectedHash) {
            Ninja-Property-Set dcuInstallStatus "NO: 1.0_generic_install.ps1: Failure. Setup file hash mismatch - got $FileHash; $(Get-Date)"
            Write-Output "Error during installation process: Setup file hash mismatch - got $FileHash; $(Get-Date)"
            THROW "File hash mismatch. Throwing it. $(Get-Date)"
        }

        # Install the application silently
        Start-Process -FilePath $installerPath -ArgumentList '/s' -Wait -NoNewWindow -ErrorAction Stop
# Clean up by removing the installer file
        Remove-Item $installerPath -Force -ErrorAction Stop
        return $true
    } catch {
        Write-Output "Failed to install Dell Command Update: $_"
        return $false
    }
}
# Main script logic
try {
# call the function to install Dell Command Update using the installer from Dell's website
    $installSuccess = Install-DellCommandUpdateUsingInstaller
# Set 'dcuInstallStatus' property based on installation success
    if ($installSuccess) {

        Ninja-Property-Set dcuInstallStatus 'YES: not configured'
        Ninja-Property-Set dcuUpdateInstalled 'YES: not configured'
        Write-Output 'Dell Command Update successfully installed'
    } else {
        Ninja-Property-Set dcuInstallStatus 'NO: Install Failed'
        Ninja-Property-Set dcuUpdateInstalled 'NO: Install Failed'
    }
} catch {
# Handle any errors during the installation process
    Write-Output "Error during installation process: $_"
# Set custom fields  on error
    Ninja-Property-Set dcuInstallStatus "NO: $_"
    Ninja-Property-Set dcuUpdateInstalled "NO: $_"
}
