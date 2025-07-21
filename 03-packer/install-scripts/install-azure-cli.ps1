$azureCliVersion = "latest"  # Can specify version if needed
$installerPath = "C:\Users\packeradmin\AzureCLI.msi"
$downloadUrl = "https://aka.ms/installazurecliwindows"

Write-Host "Downloading Azure CLI ($azureCliVersion)..."

try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing
} catch {
    Write-Host "Download failed: $($_.Exception.Message)"
    exit 1
}

Write-Host "Installing Azure CLI silently..."
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", "`"$installerPath`"", "/quiet", "/norestart" -Wait

Write-Host "Cleaning up installer..."
Remove-Item $installerPath -Force

Write-Host "Refreshing PATH environment variable..."

# Refresh PATH in current session to include new Azure CLI path
$machinePath = [System.Environment]::GetEnvironmentVariable("PATH","Machine")
$userPath = [System.Environment]::GetEnvironmentVariable("PATH","User")
$env:PATH = $machinePath + ";" + $userPath

Write-Host "Verifying Azure CLI installation..."

# Run az version to verify install
$azVersion = & az version 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Azure CLI installed successfully!"
    Write-Output $azVersion
} else {
    Write-Host "Warning: 'az' command not found. You may need to restart the shell or machine."
}
