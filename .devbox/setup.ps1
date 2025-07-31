# eShop Dev Environment Setup
Write-Host '=================================================================' -ForegroundColor Cyan
Write-Host '                eShop Development Environment Setup              ' -ForegroundColor Cyan
Write-Host '=================================================================' -ForegroundColor Cyan
Write-Host ''

# Check if running as admin, if not, elevate
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "This script needs to be run as Administrator. Restarting with elevated permissions..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# Set execution policy
Write-Host "Setting execution policy to allow script execution..." -ForegroundColor Green
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Function to check if Docker is running
function Test-DockerRunning {
    try {
        $dockerStatus = docker info 2>&1
        if ($LASTEXITCODE -eq 0) {
            return $true
        }
        return $false
    }
    catch {
        return $false
    }
}

# Create source directory if it doesn't exist
$sourceDir = "$HOME\source\repos"
if (-not (Test-Path -Path $sourceDir)) {
    Write-Host "Creating source directory at $sourceDir..." -ForegroundColor Green
    New-Item -Path $sourceDir -ItemType Directory -Force | Out-Null
}

# Clone the repository if specified
$repoPath = "$sourceDir\eShop"
if (-not (Test-Path -Path $repoPath)) {
    Write-Host "Cloning eShop repository..." -ForegroundColor Green
    git clone https://github.com/dotnet/eshop.git $repoPath
}
else {
    Write-Host "eShop repository already exists at $repoPath" -ForegroundColor Yellow
}

# Navigate to the repository
cd $repoPath

# Check if Docker Desktop is running
if (-not (Test-DockerRunning)) {
    Write-Host "Starting Docker Desktop..." -ForegroundColor Green
    Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe" -WindowStyle Hidden
    Write-Host "Waiting for Docker to start..." -ForegroundColor Yellow
    
    $timeout = 120
    $timer = 0
    $interval = 5
    
    while (-not (Test-DockerRunning) -and $timer -lt $timeout) {
        Start-Sleep -Seconds $interval
        $timer += $interval
        Write-Host "." -NoNewline -ForegroundColor Yellow
    }
    
    Write-Host ""
    
    if (-not (Test-DockerRunning)) {
        Write-Host "Docker Desktop didn't start within the timeout period." -ForegroundColor Red
        Write-Host "Please start Docker Desktop manually before continuing." -ForegroundColor Red
    }
    else {
        Write-Host "Docker Desktop is now running." -ForegroundColor Green
    }
}
else {
    Write-Host "Docker Desktop is already running." -ForegroundColor Green
}

# Install .NET HTTPS development certificates
Write-Host "Installing HTTPS development certificates..." -ForegroundColor Green
dotnet dev-certs https --trust

# Install all required .NET workloads
Write-Host "Installing all required .NET workloads..." -ForegroundColor Green
$requiredWorkloads = @(
    "aspire",
    "maui",
    "maui-android",
    "maui-ios",
    "maui-maccatalyst",
    "maui-windows",
    "maui-tizen"
)

foreach ($workload in $requiredWorkloads) {
    Write-Host "Installing .NET workload: $workload..." -ForegroundColor Green
    dotnet workload install $workload
}

# Install required libraries
Write-Host "Installing required libraries..." -ForegroundColor Green
dotnet tool install -g Microsoft.Web.LibraryManager.Cli

Write-Host "Restoring libraries for Identity.API..." -ForegroundColor Green
Push-Location "$repoPath\src\Identity.API"
libman restore
Pop-Location

# Restore NuGet packages
Write-Host "Restoring NuGet packages..." -ForegroundColor Green
dotnet restore $repoPath\eShop.sln

# Create a Visual Studio solution shortcut on the desktop
$vsShortcutPath = "$HOME\Desktop\eShop Solution.lnk"
if (-not (Test-Path -Path $vsShortcutPath)) {
    Write-Host "Creating Visual Studio solution shortcut on desktop..." -ForegroundColor Green
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($vsShortcutPath)
    $Shortcut.TargetPath = "$repoPath\eShop.Web.slnf"
    $Shortcut.Save()
}

# Setup complete!
Write-Host ""
Write-Host '=================================================================' -ForegroundColor Green
Write-Host '                 Setup Complete! Ready to develop!               ' -ForegroundColor Green
Write-Host '=================================================================' -ForegroundColor Green
Write-Host ""
Write-Host "To get started:" -ForegroundColor White
Write-Host "1. Open Visual Studio using the desktop shortcut or open $repoPath\eShop.Web.slnf" -ForegroundColor White
Write-Host "2. Ensure that Docker Desktop is running" -ForegroundColor White
Write-Host "3. Set eShop.AppHost.csproj as the startup project" -ForegroundColor White
Write-Host "4. Press F5 to build and run the application" -ForegroundColor White
Write-Host ""

# Keep the console window open
Write-Host "Press any key to continue..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")