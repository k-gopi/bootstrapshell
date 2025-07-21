$javaVersion = "17.0.11+9"
$msiUrl = "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.11%2B9/OpenJDK17U-jdk_x64_windows_hotspot_17.0.11_9.msi"
$installerPath = "C:\Users\packeradmin\temurin-jdk17.msi"

Write-Host "Downloading Temurin Java $javaVersion..."
Invoke-WebRequest -Uri $msiUrl -OutFile $installerPath -UseBasicParsing

Write-Host "Installing Java (Temurin) silently..."
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", "`"$installerPath`"", "/qn", "/norestart" -Wait

Write-Host "Cleaning up installer..."
Remove-Item $installerPath -Force

# Set environment variables
$javaHome = "C:\Program Files\Eclipse Foundation\jdk-$javaVersion"
[System.Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHome, [System.EnvironmentVariableTarget]::Machine)
$env:JAVA_HOME = $javaHome

# Add to system path
$machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
if ($machinePath -notlike "*$javaHome\bin*") {
    $newPath = "$machinePath;$javaHome\bin"
    [System.Environment]::SetEnvironmentVariable("Path", $newPath, [System.EnvironmentVariableTarget]::Machine)
}
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine")

Write-Host "Verifying Java installation..."
try {
    java -version
    Write-Host "Java installed successfully."
} catch {
    Write-Host "Java installation failed or shell restart needed."
}
