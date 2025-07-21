$gitVersion = "2.44.0"
$installerPath = "C:\Users\packeradmin\GitInstaller.exe"
$downloadUrl = "https://github.com/git-for-windows/git/releases/download/v2.44.0.windows.1/Git-2.44.0-64-bit.exe"
$maxRetries = 3
$retryDelaySeconds = 5
$downloadSuccess = $false

Write-Host "Downloading Git for Windows version $gitVersion from GitHub..."

# Retry loop
for ($i = 1; $i -le $maxRetries; $i++) {
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing
        Write-Host "✅ Download successful."
        $downloadSuccess = $true
        break
    } catch {
        Write-Host "❌ Attempt $i failed: $($_.Exception.Message)"
        if ($i -lt $maxRetries) {
            Write-Host "Retrying in $retryDelaySeconds seconds..."
            Start-Sleep -Seconds $retryDelaySeconds
        }
    }
}

if (-not $downloadSuccess) {
    Write-Host "❌ Download failed after $maxRetries attempts. Exiting script."
    exit 1
}

Write-Host "Installing Git silently..."
Start-Process -FilePath $installerPath -ArgumentList "/VERYSILENT", "/NORESTART", "/NOCANCEL" -Wait

Write-Host "Cleaning up installer..."
Remove-Item $installerPath -Force

Write-Host "Refreshing PATH for current session..."
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
            [System.Environment]::GetEnvironmentVariable("PATH", "User")

Write-Host "Verifying Git installation..."
try {
    $gitVersionOutput = & git --version
    Write-Host "✅ Git installed: $gitVersionOutput"
} catch {
    Write-Host "⚠️ Git install may require shell restart or reboot."
}
