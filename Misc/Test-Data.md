> [!IMPORTANT]
> This is for Powershell 7.

```powershell
# ============================================================
# Random Backup / Copy Test Data Generator
# ============================================================
# Press ENTER at any prompt to use the default value.
# ============================================================

Clear-Host

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "       Random Backup / Copy Test Data Generator" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press ENTER at any prompt to use the default value." -ForegroundColor Yellow
Write-Host ""

# ============================================================
# Helper Functions
# ============================================================

function Get-InputWithDefault {
    param (
        [string]$Prompt,
        [string]$Default
    )

    $InputValue = Read-Host "$Prompt [$Default]"

    if ([string]::IsNullOrWhiteSpace($InputValue)) {
        return $Default
    }

    return $InputValue
}

function Get-IntegerInput {
    param (
        [string]$Prompt,
        [int]$Default,
        [int]$Minimum = 0
    )

    while ($true) {

        $InputValue = Read-Host "$Prompt [$Default]"

        if ([string]::IsNullOrWhiteSpace($InputValue)) {
            return $Default
        }

        $Number = 0

        if ([int]::TryParse($InputValue, [ref]$Number)) {

            if ($Number -ge $Minimum) {
                return $Number
            }
        }

        Write-Host "Please enter a valid number >= $Minimum." -ForegroundColor Red
    }
}

function Convert-ToBytes {
    param (
        [string]$Size
    )

    $Size = $Size.Trim().ToUpper()

    if ($Size -match '^([\d\.]+)\s*(KB|MB|GB|B)$') {

        $Number = [double]$Matches[1]
        $Unit = $Matches[2]

        switch ($Unit) {

            "B" {
                return [long]$Number
            }

            "KB" {
                return [long]($Number * 1KB)
            }

            "MB" {
                return [long]($Number * 1MB)
            }

            "GB" {
                return [long]($Number * 1GB)
            }
        }
    }

    return $null
}

function Get-FileSizeInput {
    param (
        [string]$Prompt,
        [string]$Default
    )

    while ($true) {

        $InputValue = Read-Host "$Prompt [$Default]"

        if ([string]::IsNullOrWhiteSpace($InputValue)) {
            return Convert-ToBytes $Default
        }

        $Bytes = Convert-ToBytes $InputValue

        if ($null -ne $Bytes -and $Bytes -gt 0) {
            return $Bytes
        }

        Write-Host "Invalid size. Examples: 10KB, 50MB, 1GB" -ForegroundColor Red
    }
}

function Get-RandomFileName {

    param (
        [string]$Extension
    )

    $Characters =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

    $Name = -join (
        1..16 |
        ForEach-Object {
            $Characters[(Get-Random -Minimum 0 -Maximum $Characters.Length)]
        }
    )

    return "$Name$Extension"
}

function Create-RandomFile {

    param (
        [string]$Path,
        [long]$SizeBytes
    )

    $FileStream = [System.IO.File]::Create($Path)

    try {

        # 1 MB buffer prevents large files from consuming large
        # amounts of PowerShell memory.

        $BufferSize = 1MB
        $Buffer = New-Object byte[] $BufferSize

        $Remaining = $SizeBytes

        while ($Remaining -gt 0) {

            $WriteSize = [Math]::Min(
                $BufferSize,
                $Remaining
            )

            # Generate random data
            [System.Security.Cryptography.RandomNumberGenerator]::Fill(
                $Buffer
            )

            $FileStream.Write(
                $Buffer,
                0,
                $WriteSize
            )

            $Remaining -= $WriteSize
        }

    }
    finally {

        $FileStream.Close()
    }
}

function Create-TestFolder {

    param (
        [string]$Path,
        [int]$CurrentDepth
    )

    if (!(Test-Path $Path)) {

        New-Item `
            -ItemType Directory `
            -Path $Path `
            -Force |
            Out-Null
    }

    # --------------------------------------------------------
    # Create files in this folder
    # --------------------------------------------------------

    for ($i = 1; $i -le $FilesPerFolder; $i++) {

        $Extension = $Extensions |
            Get-Random

        $FileName = Get-RandomFileName `
            -Extension $Extension

        $FilePath = Join-Path `
            $Path `
            $FileName

        $FileSize = Get-Random `
            -Minimum $MinFileSizeBytes `
            -Maximum ($MaxFileSizeBytes + 1)

        Create-RandomFile `
            -Path $FilePath `
            -SizeBytes $FileSize

        $script:FilesCreated++

        $script:BytesCreated += $FileSize

        Write-Progress `
            -Activity "Creating test files" `
            -Status "$FilePath" `
            -PercentComplete 0
    }

    # --------------------------------------------------------
    # Stop creating subfolders if maximum depth reached
    # --------------------------------------------------------

    if ($CurrentDepth -ge $MaxDepth) {
        return
    }

    # --------------------------------------------------------
    # Create random subfolders
    # --------------------------------------------------------

    $SubFolderCount = Get-Random `
        -Minimum 0 `
        -Maximum ($SubFoldersPerFolder + 1)

    for ($i = 1; $i -le $SubFolderCount; $i++) {

        $FolderName = "Folder_" + (
            -join (
                1..8 |
                ForEach-Object {
                    [char](Get-Random -Minimum 65 -Maximum 91)
                }
            )
        )

        $SubFolderPath = Join-Path `
            $Path `
            $FolderName

        $script:FoldersCreated++

        Create-TestFolder `
            -Path $SubFolderPath `
            -CurrentDepth ($CurrentDepth + 1)
    }
}

# ============================================================
# Ask User For Configuration
# ============================================================

Write-Host "TEST DATA LOCATION" -ForegroundColor Green
Write-Host ""

$RootPath = Get-InputWithDefault `
    "Root folder" `
    "C:\BackupTest"

Write-Host ""

# ------------------------------------------------------------
# Folder configuration
# ------------------------------------------------------------

Write-Host "FOLDER SETTINGS" -ForegroundColor Green
Write-Host ""

$FolderCount = Get-IntegerInput `
    "Number of top-level folders" `
    20 `
    1

$SubFoldersPerFolder = Get-IntegerInput `
    "Maximum subfolders per folder" `
    5 `
    0

$MaxDepth = Get-IntegerInput `
    "Maximum folder depth" `
    3 `
    1

Write-Host ""

# ------------------------------------------------------------
# File configuration
# ------------------------------------------------------------

Write-Host "FILE SETTINGS" -ForegroundColor Green
Write-Host ""

$FilesPerFolder = Get-IntegerInput `
    "Files per folder" `
    50 `
    0

$MinFileSizeBytes = Get-FileSizeInput `
    "Minimum file size" `
    "1KB"

$MaxFileSizeBytes = Get-FileSizeInput `
    "Maximum file size" `
    "10MB"

while ($MaxFileSizeBytes -lt $MinFileSizeBytes) {

    Write-Host ""
    Write-Host "Maximum file size cannot be smaller than minimum." -ForegroundColor Red

    $MaxFileSizeBytes = Get-FileSizeInput `
        "Maximum file size" `
        "10MB"
}

Write-Host ""

# ------------------------------------------------------------
# Extensions
# ------------------------------------------------------------

Write-Host "FILE EXTENSIONS" -ForegroundColor Green
Write-Host ""

$ExtensionInput = Get-InputWithDefault `
    "File extensions (comma separated)" `
    ".txt,.log,.dat,.bin,.csv,.xml,.json,.bak"

$Extensions = $ExtensionInput.Split(",") |
    ForEach-Object {
        $_.Trim()
        if ($_ -notmatch '^\.') {
            ".$_"
        }
    }

# ============================================================
# Display Configuration
# ============================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "CONFIGURATION" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

Write-Host "Root Path              : $RootPath"
Write-Host "Top-Level Folders      : $FolderCount"
Write-Host "Max Subfolders         : $SubFoldersPerFolder"
Write-Host "Max Folder Depth       : $MaxDepth"
Write-Host "Files Per Folder       : $FilesPerFolder"
Write-Host "Minimum File Size      : $($MinFileSizeBytes / 1KB) KB"
Write-Host "Maximum File Size      : $($MaxFileSizeBytes / 1MB) MB"
Write-Host "Extensions             : $($Extensions -join ', ')"
Write-Host "============================================================"
Write-Host ""

$Confirm = Read-Host "Start generating test data? (Y/N)"

if ($Confirm -notmatch '^Y$') {

    Write-Host ""
    Write-Host "Cancelled." -ForegroundColor Yellow

    exit
}

# ============================================================
# Prepare Destination
# ============================================================

if (Test-Path $RootPath) {

    Write-Host ""
    Write-Host "WARNING: The destination already exists:" -ForegroundColor Yellow
    Write-Host $RootPath -ForegroundColor Yellow
    Write-Host ""

    $Continue = Read-Host "Continue? (Y/N)"

    if ($Continue -notmatch '^Y$') {

        Write-Host "Cancelled." -ForegroundColor Yellow

        exit
    }
}
else {

    New-Item `
        -ItemType Directory `
        -Path $RootPath `
        -Force |
        Out-Null
}

# ============================================================
# Generate Data
# ============================================================

$FilesCreated = 0
$FoldersCreated = 0
$BytesCreated = [long]0

$StartTime = Get-Date

Write-Host ""
Write-Host "Generating test data..." -ForegroundColor Green
Write-Host ""

for ($i = 1; $i -le $FolderCount; $i++) {

    $FolderName = "TestFolder_{0:D3}" -f $i

    $FolderPath = Join-Path `
        $RootPath `
        $FolderName

    $FoldersCreated++

    Write-Host "Creating $FolderName..." -ForegroundColor Cyan

    Create-TestFolder `
        -Path $FolderPath `
        -CurrentDepth 1
}

Write-Progress `
    -Activity "Creating test files" `
    -Completed

$EndTime = Get-Date

$Elapsed = $EndTime - $StartTime

# ============================================================
# Final Statistics
# ============================================================

$TotalGB = [Math]::Round(
    $BytesCreated / 1GB,
    2
)

$TotalMB = [Math]::Round(
    $BytesCreated / 1MB,
    2
)

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "                 GENERATION COMPLETE" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green

Write-Host ""
Write-Host "Location       : $RootPath"
Write-Host "Files Created  : $FilesCreated"
Write-Host "Folders Created: $FoldersCreated"
Write-Host "Total Size     : $TotalMB MB ($TotalGB GB)"
Write-Host "Time Taken     : $($Elapsed.ToString())"

if ($Elapsed.TotalSeconds -gt 0) {

    $WriteSpeed = $BytesCreated / $Elapsed.TotalSeconds

    Write-Host "Generation Rate: $([Math]::Round($WriteSpeed / 1MB, 2)) MB/s"
}

Write-Host ""
Write-Host "Test data is ready for backup/copy testing." -ForegroundColor Green
Write-Host ""
```

```
