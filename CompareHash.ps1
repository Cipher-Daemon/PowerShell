#This will compare the hashes that you download from the internet and the one generated by you to ensure the hashes matches without human error

$FilePath = read-host -prompt "What is the full file path?"
$OriginalHash = read-host -prompt "What is the hash provided?"
$HashAlgorithm = read-host -prompt "What is the hash algorithm?"
$MyHash = get-filehash -algorithm $HashAlgorithm $FilePath

write-host "Vendor hash is: $OriginalHash"
write-host "Your hash is:" $MyHash.Hash

if($OriginalHash -eq $MyHash.Hash) {
    Write-Host "Match" -BackgroundColor black -ForegroundColor Cyan
} else {
    write-host "No Match" -BackgroundColor black -ForegroundColor Red
}
