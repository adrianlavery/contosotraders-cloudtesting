Install-packageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name Az -Repository PSGallery -Force

param($storageAccountKey, $storageAccountName)

New-Item -Path "C:\" -Name "ReactApp" -ItemType Directory
New-Item -Path "C:\ReactApp" -Name "static" -ItemType Directory
New-Item -Path "C:\ReactApp\static" -Name "css"-ItemType Directory
New-Item -Path "C:\ReactApp\static" -Name "js"-ItemType Directory
New-Item -Path "C:\ReactApp\static" -Name "media"-ItemType Directory

$containerName = '$web'
$destinationPath = 'C:\ReactApp'

$ctx = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
$blobs = Get-AzStorageBlob -Context $ctx -Container $containerName

foreach ($blob in $blobs) {
    $blobName = $blob.Name
    $destinationFile = Join-Path -Path $destinationPath -ChildPath $blobName
    Get-AzStorageBlobContent -Blob $blobName -Container $containerName -Destination $destinationFile -Context $ctx -Force
}