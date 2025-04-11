# Set script start time
$startTime = Get-Date

# Get app version from pubspec.yaml
$appVersion = Select-String -Path "pubspec.yaml" -Pattern "version:\s*(\d+\.\d+\.\d+)" | ForEach-Object { $_.Matches.Groups[1].Value }

# Define progress tracking variables
$global:step = 0
$totalSteps = 7

# Output log file for non-verbose mode
$outputLog = "build_output.log"
if (Test-Path $outputLog) { Remove-Item $outputLog -Force }

# Check for verbose flag (-v)
$v = $false
if ($args -contains "-v") { $v = $true }

# Generate Intro Header
$intro = "SigaAutomator App Version: $appVersion"
$line = "-" * $intro.Length
Write-Host "$intro"
Write-Host "$line"

# Function to display progress
function Show-Progress {
    param ([string]$message)
    $global:step++
    Write-Host "[$global:step/$totalSteps] $message"
}

# Function to run a command
function Run-Command {
    param ([string[]]$command, [string]$successMessage)

    # Run the process and capture output
    $output = & $command[0] $command[1..$command.Length] 2>&1
    $output -replace "ΓêÜ", "✔" | Add-Content $outputLog

    # Count warnings
    $warningCount = ($output | Select-String -Pattern "warning" -CaseSensitive).Count

    # Handle verbose output
    if ($v) {
        $output | ForEach-Object { "      $_" -replace "ΓêÜ", "✔" }
    }

    # Handle errors
    if ($output -match "fatal|error") {
        Write-Host "`n❌ Error encountered in step $global:step:"
        $output | ForEach-Object { "      $_" }
        Exit 1
    } elseif ($warningCount -gt 0) {
        Write-Host "      $successMessage with $warningCount warning(s)."
    } else {
        Write-Host "      $successMessage"
    }
}

# Function to run a Git command
function Run-GitCommand {
    param ([string[]]$gitCommand, [string]$successMessage)
    
    $output = & git @gitCommand 2>&1
    $output | Add-Content $outputLog

    $warningCount = ($output | Select-String -Pattern "warning" -CaseSensitive).Count

    if ($v) {
        $output | ForEach-Object { "      $_" }
    }

    if ($output -match "fatal|error") {
        Write-Host "`n❌ Error encountered in step $global:step:"
        $output | ForEach-Object { "      $_" }
        Exit 1
    } elseif ($warningCount -gt 0) {
        Write-Host "      $successMessage with $warningCount warning(s)."
    } else {
        Write-Host "      $successMessage"
    }
}

# Update version in Inno Setup script
(Get-Content ".\pack_windows.iss") -replace "\d+\.\d+\.\d+", $appVersion | Set-Content ".\pack_windows.iss"

# Step 1: Build APK
Show-Progress "Building APK..."
Run-Command @("flutter", "build", "apk", "--profile", "--dart-define-from-file=.env", "--split-per-abi") "Done Building APK"

# Move the APK
$abi7 = "armeabi-v7a"
$abi8 = "arm64-v8a"
$x86 = "x86_64"

$apkPath7 = ".\build\app\outputs\flutter-apk\app-$abi7-profile.apk"
$apkPath8 = ".\build\app\outputs\flutter-apk\app-$abi8-profile.apk"
$apkPathx86 = ".\build\app\outputs\flutter-apk\app-$x86-profile.apk"
$destPath7 = ".\generated-apk\SigaAutomator-${appVersion}_$abi7.apk"
$destPath8 = ".\generated-apk\SigaAutomator-${appVersion}_$abi8.apk"
$destPathx86 = ".\generated-apk\SigaAutomator-${appVersion}_$x86.apk"


# Remove old APK if exists
if (Test-Path $destPath7) {
    Remove-Item $destPath7 -Force
    Remove-Item $destPath8 -Force
    Remove-Item $destPathx86 -Force
}

Move-Item -Path $apkPath7 -Destination $destPath7
Move-Item -Path $apkPath8 -Destination $destPath8
Move-Item -Path $apkPathx86 -Destination $destPathx86

# Step 2: Build Windows App
Show-Progress "Building Windows App..."
Run-Command @("flutter", "build", "windows", "--profile", "--dart-define-from-file=secretary.json") "Done Building Windows App"

# Step 3: Pack Windows App
Show-Progress "Packing Windows App..."
$packOutput = & "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" ".\pack_windows.iss" 2>&1
$packOutput | Add-Content $outputLog

$warningCount = ($packOutput | Select-String -Pattern "warning" -CaseSensitive).Count

if ($v) {
    $packOutput | ForEach-Object { "      $_" }
}

if ($warningCount -gt 0) {
    Write-Host "      Done Packing Windows App with $warningCount warning(s)."
} else {
    Write-Host "      Done Packing Windows App"
}

# Step 4: Update repository
Show-Progress "Updating the repo..."
Run-GitCommand @("remote", "update") "Done Updating the repo"
Run-GitCommand @("pull") "Done Pulling latest changes"

# Step 5: Commit and push changes
Show-Progress "Committing and pushing changes..."
Run-GitCommand @("add", ".") "Staged changes"

# Generate a random commit message
$commitMessages = @(
    "Update APK build",
    "New profile build, hope this works",
    "Fresh build, testing changes",
    "Rebuilding APK for verification",
    "Another day, another build"
)
$commitMessage = $commitMessages | Get-Random

Run-GitCommand @("commit", "-m", $commitMessage) "Committed changes"
Run-GitCommand @("push", "origin", "main") "Pushed to repository"

# Step 6: Delete old GitHub release if exists
$repoPath = "..\SigaAutomator\"
$releaseVersion = "v$appVersion"
$filesToUpload = Get-ChildItem "generated-apk" | Where-Object { $_.Name -like "*$appVersion*" }

Push-Location $repoPath
$repo = "onodnawij/SigaAutomator"

$release = gh release view $releaseVersion --repo $repo --json url 2>$null

if ($release) {
    Show-Progress "Deleting old release..."
    gh release delete $releaseVersion --repo $repo --yes 2>&1 | Add-Content $outputLog
}

# Step 7: Create a new GitHub release
Show-Progress "Creating GitHub release..."
gh release create $releaseVersion $filesToUpload --title "Version $appVersion" --notes "Fixed Supabase integration" 2>&1 | Add-Content $outputLog
Write-Host "      Done Creating GitHub release"

Pop-Location

# Script completed
$endTime = Get-Date
$outro = "SigaAutomator Build Completed at: $endTime"

Write-Host ("-" * $outro.Length)
Write-Host "$outro"
