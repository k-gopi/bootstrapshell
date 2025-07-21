# Variables
$terraformVersion = "1.5.7"  # Change to latest if needed
$terraformZipUrl = "https://releases.hashicorp.com/terraform/$terraformVersion/terraform_${terraformVersion}_windows_amd64.zip"
$installPath = "C:\terraform"

Write-Host "Downloading Terraform version $terraformVersion from $terraformZipUrl ..."

# Create install directory if it doesn't exist
if (-Not (Test-Path -Path $installPath)) {
    New-Item -ItemType Directory -Path $installPath | Out-Null
}

# Download zip file
$zipPath = "$env:TEMP\terraform.zip"
Invoke-WebRequest -Uri $terraformZipUrl -OutFile $zipPath

Write-Host "Extracting Terraform to $installPath ..."
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $installPath)

# Cleanup zip file
Remove-Item $zipPath

Write-Host "Adding Terraform folder to system PATH ..."
$oldPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
if ($oldPath -notlike "*$installPath*") {
    $newPath = $oldPath + ";" + $installPath
    [Environment]::SetEnvironmentVariable("Path", $newPath, [EnvironmentVariableTarget]::Machine)
    Write-Host "PATH updated. You may need to restart your session to recognize Terraform."
} else {
    Write-Host "Terraform path already present in PATH."
}

Write-Host "Verifying Terraform installation ..."
$terraformExe = Join-Path $installPath "terraform.exe"

if (Test-Path $terraformExe) {
    $version = & $terraformExe -version
    Write-Host "Terraform installed successfully. Version info:"
    Write-Host $version
} else {
    Write-Error "Terraform executable not found!"
}
