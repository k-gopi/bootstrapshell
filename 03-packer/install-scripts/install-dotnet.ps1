$dotnetVersion = "8.0.412"
$dotnetInstaller = "C:\Users\packeradmin\dotnet-sdk-$dotnetVersion.exe"
$downloadUrl = "https://builds.dotnet.microsoft.com/dotnet/Sdk/8.0.412/dotnet-sdk-8.0.412-win-x64.exe"

Write-Host "Downloading .NET SDK $dotnetVersion..."

try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $dotnetInstaller -UseBasicParsing
} catch {
    Write-Host "Download failed: $($_.Exception.Message)"
    exit 1
}

Write-Host "Installing .NET SDK $dotnetVersion..."
Start-Process -FilePath $dotnetInstaller -ArgumentList "/quiet", "/norestart" -Wait

Write-Host "Cleaning up installer file..."
Remove-Item $dotnetInstaller -Force

Write-Host ".NET SDK $dotnetVersion installed successfully!"

# Optional: verify installation
$installedVersion = & dotnet --version
Write-Host "Installed .NET version: $installedVersion"
