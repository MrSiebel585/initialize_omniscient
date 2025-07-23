# PowerShell Strict Mode
Set-StrictMode -Version Latest

# ----------------------
# Configurable Variables
# ----------------------
$SourceRoot = "C:\Users\MSI\Developments"
$TargetDir = "C:\Users\MSI\Developments\master_installers"
$LogFile   = "$TargetDir\arsenal_copy.log"
$Patterns  = @("*.sh", "*.ps1", "*.bat", "*.cmd", "*.py")

# ----------------------
# Create target if needed
# ----------------------
if (-not (Test-Path $TargetDir)) {
    Write-Host "[+] Creating destination directory: $TargetDir" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
}

# ----------------------
# Timestamp log header
# ----------------------
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"===== Copy started: $timestamp =====`n" | Out-File -Append $LogFile

# ----------------------
# File Discovery & Copy
# ----------------------
foreach ($pattern in $Patterns) {
    $files = Get-ChildItem -Path $SourceRoot -Recurse -Include "*arsenal*$pattern" -File -ErrorAction SilentlyContinue

    foreach ($file in $files) {
        $destPath = Join-Path $TargetDir $file.Name

        try {
            # Optional: backup if exists
            if (Test-Path $destPath) {
                $backupName = "$($file.BaseName)_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')$($file.Extension)"
                Copy-Item -Path $destPath -Destination "$TargetDir\$backupName"
                Write-Host "[~] Backed up existing: $($file.Name)" -ForegroundColor DarkYellow
                "`tBacked up existing: $($file.Name) -> $backupName" | Out-File -Append $LogFile
            }

            # Copy file to destination
            Copy-Item -Path $file.FullName -Destination $destPath -Force
            Write-Host "[+] Copied: $($file.FullName) -> $destPath" -ForegroundColor Green
            "`tCopied: $($file.FullName) -> $destPath" | Out-File -Append $LogFile
        }
        catch {
            Write-Host "[!] Failed to copy: $($file.FullName) — $_" -ForegroundColor Red
            "`tFAILED: $($file.FullName) — $_" | Out-File -Append $LogFile
        }
    }
}

# ----------------------
# Completion Message
# ----------------------
$done = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"`n===== Copy finished: $done =====`n" | Out-File -Append $LogFile
Write-Host "[✓] Arsenal installer files copied successfully." -ForegroundColor Cyan
Write-Host "[📜] Log written to: $LogFile" -ForegroundColor DarkGray
