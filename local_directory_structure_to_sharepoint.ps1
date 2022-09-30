## Get the Token
$clientId = "Application (Client) ID"
$clientSecret = "Client secret"
$tenantName = "TenantName.onmicrosoft.com"

$tokenBody = @{

    Grant_Type    = 'client_credentials'
    Scope         = 'https://graph.microsoft.com/.default'
    Client_Id     = $clientId
    Client_Secret = $clientSecret
}

$tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantName/oauth2/v2.0/token" -Method POST -Body $tokenBody -ErrorAction Stop

$headers = @{

    "Authorization" = "Bearer $($tokenResponse.access_token)"
    "Content-Type"  = "application/json"
}

## Use the SharePoint groups ObjectID. From this we'll get the drive ID.
$site_objectid = "Groups ObjectID"

## Create all the folders on the SharePoint site first. I've set microsoft.graph.conflictBehavior below to fail because I never want to rename or replace folders.
$baseDirectory = "/data"
    $directories = get-childItem -path $baseDirectory -recurse -directory | Where-Object {$_.LastWriteTime -gt (Get-Date).AddDays(-4)}

    foreach ($directory in $directories) {
        $URL = "https://graph.microsoft.com/v1.0/groups/$site_objectid/sites/root"
$subsite_ID = (Invoke-RestMethod -Headers $headers -Uri $URL -Method Get).ID

$URL = "https://graph.microsoft.com/v1.0/sites/$subsite_ID/drives"
$Drives = Invoke-RestMethod -Headers $headers -Uri $URL -Method Get

$Document_drive_ID = ($Drives.value | Where-Object { $_.name -eq 'Documents' }).id
        $createFolderURL = "https://graph.microsoft.com/v1.0/drives/$Document_drive_ID/items/root:{0}:/children"  -f $directory.parent.FullName
        $file = $directory.Name

                $uploadFolderRequestBody = @{
            name= "$file"
            folder = @{}
            "@microsoft.graph.conflictBehavior"= "fail"
        } | ConvertTo-Json

       invoke-restMethod -headers $headers -method Post -body $uploadFolderRequestBody -contentType "application/json" -uri $createFolderURL
    }

## Upload the files. I'm only adding files that are 4 days old or less because I run the script every 3 days for backup.
## These are set in the $sharefiles variable. To upload all files just remove everything after the pipe.

$sharefiles = get-childItem  $baseDirectory -recurse | Where-Object {$_.LastWriteTime -gt (Get-Date).AddDays(-4)}
    foreach ($sharefile in $sharefiles) {
$Filepath = $sharefile.FullName
$URL = "https://graph.microsoft.com/v1.0/groups/$site_objectid/sites/root"
$subsite_ID = (Invoke-RestMethod -Headers $headers -Uri $URL -Method Get).ID

$URL = "https://graph.microsoft.com/v1.0/sites/$subsite_ID/drives"
$Drives = Invoke-RestMethod -Headers $headers -Uri $URL -Method Get

$Document_drive_ID = ($Drives.value | Where-Object { $_.name -eq 'Documents' }).id
$Filename = $sharefile.Name

$upload_session = "https://graph.microsoft.com/v1.0/drives/$Document_drive_ID/root:{0}/$($Filename):/createUploadSession" -f $sharefile.directory.FullName

$upload_session_url = (Invoke-RestMethod -Uri $upload_session -Headers $headers -Method Post).uploadUrl

## We'll upload files in chunks.

$ChunkSize = 62259200
$file = New-Object System.IO.FileInfo($Filepath)
$reader = [System.IO.File]::OpenRead($Filepath)
$buffer = New-Object -TypeName Byte[] -ArgumentList $ChunkSize
$position = 0
$counter = 0

Write-Host "ChunkSize: $ChunkSize" -ForegroundColor Cyan
Write-Host "BufferSize: $($buffer.Length)" -ForegroundColor Cyan

$moreData = $true


While ($moreData) {
    #Read a chunk
    $bytesRead = $reader.Read($buffer, 0, $buffer.Length)
    $output = $buffer
    If ($bytesRead -ne $buffer.Length) {
        #no more data to be read
        $moreData = $false
        #shrink the output array to the number of bytes
        $output = New-Object -TypeName Byte[] -ArgumentList $bytesRead
        [Array]::Copy($buffer, $output, $bytesRead)
        Write-Host "no more data" -ForegroundColor Yellow
    }
    #Upload the chunk
    $Header = @{
        'Content-Range'  = "bytes $position-$($position + $output.Length - 1)/$($file.Length)"
    }

    Write-Host "Content-Range  = bytes $position-$($position + $output.Length - 1)/$($file.Length)" -ForegroundColor Cyan
    #$position = $position + $output.Length - 1
    $position = $position + $output.Length
    Invoke-RestMethod -Method Put -Uri $upload_session_url -Body $output -Headers $Header -SkipHeaderValidation
    #Increment counter
    $counter++
}
$reader.Close()
}