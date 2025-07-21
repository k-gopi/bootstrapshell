# Define Packer version and URLs
$packerVersion = "1.9.5"  # You can update to latest version manually if needed
$zipUrl = "https://releases.hashicorp.com/packer/$packerVersion/packer_${packerVersion}_windows_amd64.zip"
$downloadPath = "$env:TEMP\packer.zip"
$installPath = "C:\packer"

Write-Host "Downloading Packer version $packerVersion from $zipUrl ..."
Invoke-WebRequest -Uri $zipUrl -OutFile $downloadPath -UseBasicParsing

Write-Host "Extracting Packer to $installPath ..."
if (Test-Path $installPath) {
    Remove-Item -Path $installPath -Recurse -Force
}
New-Item -Path $installPath -ItemType Directory | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($downloadPath, $installPath)

Write-Host "Adding Packer folder to system PATH ..."
$oldPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
if ($oldPath -notlike "*$installPath*") {
    $newPath = "$oldPath;$installPath"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
    Write-Host "PATH updated. You may need to restart your session to recognize Packer."
} else {
    Write-Host "Packer path already present in PATH."
}

Write-Host "Cleaning up installer zip ..."
Remove-Item -Path $downloadPath -Force

Write-Host "Verifying Packer installation ..."
$env:Path += ";$installPath"  # Temporarily update current session path
try {
    $version = & packer.exe --version
    Write-Host "Packer installed successfully. Version: $version"
} catch {
    Write-Host "Could not verify Packer installation. You may need to restart the session."
}
