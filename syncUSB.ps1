# Define variables
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$filesToCopyPath = Join-Path $scriptDirectory "FilesToSync.txt"
$zipFilePath = Join-Path $scriptDirectory "XiboInstall.zip"
$usbDriveLabel = "XiboPlayer"

# Function to create a ZIP file while preserving paths
function Create-ZipWithPaths {
    param (
        [string]$zipFilePath,
        [array]$files
    )

    # Remove existing ZIP if it exists
    if (Test-Path $zipFilePath) {
        Remove-Item $zipFilePath -Force
    }

    # Create a temporary folder to stage the files
    $tempFolder = Join-Path $scriptDirectory "TempZip"
    if (Test-Path $tempFolder) {
        Remove-Item -Recurse -Force $tempFolder
    }
    New-Item -ItemType Directory -Path $tempFolder | Out-Null

    # Copy files to the temporary folder while preserving relative paths
    foreach ($file in $files) {
        $absolutePath = Resolve-Path -Path (Join-Path $scriptDirectory $file) -ErrorAction SilentlyContinue
        if ($absolutePath) {
            $destinationPath = Join-Path $tempFolder $file
            New-Item -ItemType Directory -Path (Split-Path $destinationPath) -Force | Out-Null
            Copy-Item -Path $absolutePath -Destination $destinationPath -Force
        } else {
            Write-Host "File not found: $file" -ForegroundColor Yellow
        }
    }

    # Create the ZIP file from the temporary folder
    Write-Host "Creating ZIP file..." -ForegroundColor Green
    Start-Sleep -Seconds 1
    Compress-Archive -Path $tempFolder\* -DestinationPath $zipFilePath
    Write-Host "ZIP file created: $zipFilePath" -ForegroundColor Green
    Start-Sleep -Seconds 1

    # Clean up the temporary folder
    Remove-Item -Recurse -Force $tempFolder
}

# Main Script
Write-Host "Checking for FilesToSync.txt..." -ForegroundColor Cyan
if (Test-Path $filesToCopyPath) {
    Write-Host "Files to sync found." -ForegroundColor Green
    Start-Sleep -Seconds 1

    # Read the list of files to copy
    $filesToCopy = Get-Content $filesToCopyPath

    # Create the ZIP file
    Create-ZipWithPaths -zipFilePath $zipFilePath -files $filesToCopy

    # Look for the USB drive
    Write-Host "Looking for USB..." -ForegroundColor Cyan
    Start-Sleep -Seconds 1
    $usbDrive = Get-Volume | Where-Object { $_.FileSystemLabel -eq $usbDriveLabel }

    if ($usbDrive) {
        # Get the drive letter
        $usbDriveLetter = $usbDrive.DriveLetter
        Write-Host "USB found at ${usbDriveLetter}:" -ForegroundColor Green
        Start-Sleep -Seconds 1

        # Copy the ZIP file to the USB drive
        $zipDestination = Join-Path "${usbDriveLetter}:\" $(Split-Path -Leaf $zipFilePath)
        Write-Host "Copying file to ${usbDriveLetter}:..." -ForegroundColor Cyan
        Start-Sleep -Seconds 1
        Copy-Item -Path $zipFilePath -Destination $zipDestination -Force
        Write-Host "ZIP file copied to USB: $zipDestination" -ForegroundColor Green

        # Extract the ZIP file on the USB drive
        $extractPath = "${usbDriveLetter}:"
        Write-Host "Extracting ZIP file to USB..." -ForegroundColor Cyan
        Start-Sleep -Seconds 1
        Expand-Archive -Path $zipDestination -DestinationPath $extractPath -Force
        Write-Host "ZIP file extracted to USB root: $extractPath" -ForegroundColor Green

    } else {
        Write-Host "USB drive not found!" -ForegroundColor Red
        Start-Sleep -Seconds 1
    }
} else {
    Write-Host "${filesToCopyPath} not found!" -ForegroundColor Red
    Start-Sleep -Seconds 1
}

# Pause at the end
Write-Host "Process complete. Press any key to exit." -ForegroundColor Cyan
Pause
