Write-Host "🔄 STEP 1: Checking if Docker Desktop is already installed..."

$dockerPath = "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"

if (Test-Path $dockerPath) {
    Write-Host "✅ Docker Desktop is already installed."
} elseif (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Host "🔄 Installing Docker Desktop using Chocolatey..."
    choco install docker-desktop -y
} else {
    Write-Host "🔄 Downloading Docker Desktop installer..."
    $installerUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
    $installerPath = "$env:TEMP\DockerDesktopInstaller.exe"

    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing

    Write-Host "🔄 Installing Docker Desktop silently..."
    Start-Process -FilePath $installerPath -ArgumentList "install", "--quiet", "--accept-license" -Wait

    Remove-Item $installerPath -Force
}

Write-Host "🔄 STEP 2: Adding current user to 'docker-users' group..."

$groupName = "docker-users"
$currentUser = "$env:COMPUTERNAME\$env:USERNAME"

# Create group if it doesn't exist
if (-not (Get-LocalGroup -Name $groupName -ErrorAction SilentlyContinue)) {
    Write-Host "Creating group: $groupName"
    New-LocalGroup -Name $groupName -Description "Docker Users Group"
} else {
    Write-Host "Group $groupName already exists."
}

# Add current user to the group if not already a member
$members = Get-LocalGroupMember -Group $groupName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name

if ($members -notcontains $currentUser) {
    Write-Host "Adding $currentUser to $groupName"
    Add-LocalGroupMember -Group $groupName -Member $currentUser
} else {
    Write-Host "$currentUser is already a member of $groupName"
}

Write-Host "🔄 STEP 3: Verifying Docker installation..."

$dockerBin = "$env:ProgramFiles\Docker\Docker\resources\bin"
$env:PATH += ";$dockerBin"

try {
    $version = & "$dockerBin\docker.exe" version --format "{{.Client.Version}}" 2>$null
    if ($version) {
        Write-Host "✅ Docker version installed: $version"
    } else {
        Write-Host "⚠️ Docker is installed but version could not be determined."
    }
} catch {
    Write-Host "❌ Docker is not installed or failed to run."
    exit 1
}
