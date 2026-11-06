# Check if running as Administrator
$IsAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Write-Host "Requesting Administrator privileges..."

    Start-Process powershell.exe `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
        -Verb RunAs

    exit
}

# ============================================================
# Remove all HP printers and HP printer drivers
# Run PowerShell as Administrator
# ============================================================

Write-Host "Starting HP printer cleanup..." -ForegroundColor Cyan

# Stop Print Spooler to clear pending activity
Write-Host "`nStopping Print Spooler..."
Stop-Service Spooler -Force -ErrorAction SilentlyContinue
Start-Service Spooler

# ------------------------------------------------------------
# 1. Remove HP printer devices / queues
# ------------------------------------------------------------

Write-Host "`nSearching for HP printers..." -ForegroundColor Yellow

$HPPrinters = Get-Printer | Where-Object {
    $_.Name -match "HP|Hewlett-Packard" -or
    $_.DriverName -match "HP|Hewlett-Packard"
}

foreach ($Printer in $HPPrinters) {

    Write-Host "Removing printer: $($Printer.Name)" -ForegroundColor Red

    try {
        Remove-Printer -Name $Printer.Name -Confirm:$false -ErrorAction Stop
    }
    catch {
        Write-Warning "Could not remove printer: $($Printer.Name)"
    }
}

# ------------------------------------------------------------
# 2. Remove HP printer drivers
# ------------------------------------------------------------

Write-Host "`nSearching for HP printer drivers..." -ForegroundColor Yellow

$HPDrivers = Get-PrinterDriver | Where-Object {
    $_.Name -match "HP|Hewlett-Packard"
}

foreach ($Driver in $HPDrivers) {

    Write-Host "Removing driver: $($Driver.Name)" -ForegroundColor Red

    try {
        Remove-PrinterDriver `
            -Name $Driver.Name `
            -RemoveFromDriverStore `
            -Confirm:$false `
            -ErrorAction Stop
    }
    catch {
        Write-Warning "Could not remove driver: $($Driver.Name)"
    }
}

# ------------------------------------------------------------
# 3. Restart Print Spooler
# ------------------------------------------------------------

Write-Host "`nRestarting Print Spooler..."
Restart-Service Spooler -Force

# ------------------------------------------------------------
# 4. Show anything HP-related that remains
# ------------------------------------------------------------

Write-Host "`nRemaining HP printers:" -ForegroundColor Cyan

Get-Printer |
    Where-Object {
        $_.Name -match "HP|Hewlett-Packard" -or
        $_.DriverName -match "HP|Hewlett-Packard"
    } |
    Format-Table Name, DriverName -AutoSize

Write-Host "`nRemaining HP printer drivers:" -ForegroundColor Cyan

Get-PrinterDriver |
    Where-Object {
        $_.Name -match "HP|Hewlett-Packard"
    } |
    Format-Table Name -AutoSize

Write-Host "`nHP printer cleanup complete." -ForegroundColor Green

Write-Host ""
Read-Host "Press Enter to exit"