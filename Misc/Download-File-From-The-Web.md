# Download Files The Quick Way

PowerShell version 2 Compatibility

```powershell
$URL = Read-host "URL"
$Path = read-host "Path to save"
(New-Object System.Net.WebClient).DownloadFile ($URL, $Path)
```

PowerShell version 7+

```powershell
Invoke-WebRequest -Uri $DownloadURL -OutFile $Output
```

PowerShell version 5

```powershell
Invoke-WebRequest -Uri $DownloadURL -OutFile $Output -UseBasicParsing
```
