# install-node.ps1

$ErrorActionPreference = "Stop"

# Download latest Node.js LTS
$nodeInstallerUrl = "https://nodejs.org/dist/v20.14.0/node-v20.14.0-x64.msi"
$nodeInstallerPath = "$env:TEMP\node-installer.msi"

Write-Host "⬇️  Downloading Node.js LTS..."
Invoke-WebRequest -Uri $nodeInstallerUrl -OutFile $nodeInstallerPath

Write-Host "🛠️  Installing Node.js silently..."
Start-Process "msiexec.exe" -ArgumentList "/i `"$nodeInstallerPath`" /qn /norestart" -Wait

# Manually add Node.js to the current session PATH
$nodePath = "C:\Program Files\nodejs"
if (Test-Path $nodePath) {
    $env:Path = "$nodePath;$env:Path"
} else {
    Write-Host "❌ Node.js install folder not found at $nodePath"
}

# Clean up
Remove-Item $nodeInstallerPath -Force

Write-Host "✅ Node.js installed. Verifying version..."
node -v
npm -v
