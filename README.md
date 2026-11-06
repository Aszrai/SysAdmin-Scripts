**HP Printer Cleanup Tool**
A PowerShell utility for removing HP printer queues and HP printer drivers from Windows.

The script automatically requests Administrator privileges, removes detected HP printers and drivers, restarts the Windows Print Spooler, and displays any HP printer components that remain.

**Features**
Automatically requests Administrator privileges
Detects printers containing HP or Hewlett-Packard
Removes matching printer queues
Removes matching HP printer drivers from the Windows Driver Store
Restarts the Windows Print Spooler
Displays any HP printers or drivers that remain after cleanup
Waits for user input before closing so cleanup results can be reviewed
Includes basic error handling if a printer or driver cannot be removed
Requirements
Windows 10 or Windows 11
Windows PowerShell
Administrator privileges
Windows Print Management PowerShell cmdlets
Usage
**1. Download the script**
Download the .ps1 file to the Windows computer that needs HP printer cleanup.

For example:

HP-Printer-Cleanup.ps1
**2. Run PowerShell**
Navigate to the folder containing the script:

cd "C:\Path\To\Script"
**3. Run the script**
.\HP-Printer-Cleanup.ps1
The script checks whether it is running with Administrator privileges.

If it is not, it will automatically relaunch itself using:

Start-Process powershell.exe -Verb RunAs
Accept the Windows UAC prompt to continue.

**What the Script Does**
1. Checks Administrator Privileges
The script determines whether the current PowerShell process is elevated.

If necessary, it relaunches itself as Administrator.

2. Restarts the Print Spooler
The Windows Print Spooler is stopped and started to clear pending printer activity before cleanup begins.

3. Finds HP Printers
The script searches installed printer queues using:

Get-Printer
A printer is considered HP-related when either its printer name or driver name contains:

HP
Hewlett-Packard
Matching printer queues are removed with:

Remove-Printer
4. Removes HP Printer Drivers
Installed printer drivers are checked using:

Get-PrinterDriver
Drivers containing HP or Hewlett-Packard are removed using:

Remove-PrinterDriver -RemoveFromDriverStore
This attempts to remove the driver package from the Windows Driver Store in addition to removing the installed printer driver.

5. Restarts the Print Spooler
After printer and driver removal is complete, the Print Spooler is restarted.

6. Verifies Cleanup
The script performs another search and displays:

Remaining HP printer queues
Remaining HP printer drivers
This makes it easy to identify components that could not be automatically removed.

7. Waits Before Closing
When cleanup is complete, the script displays:

Press Enter to exit
This prevents the PowerShell window from immediately closing and allows the technician to review the results.

Example Output
Starting HP printer cleanup...

Stopping Print Spooler...

Searching for HP printers...
Removing printer: HP LaserJet Pro

Searching for HP printer drivers...
Removing driver: HP Universal Printing PCL 6

Restarting Print Spooler...

Remaining HP printers:

Remaining HP printer drivers:

HP printer cleanup complete.

Press Enter to exit:
Execution Policy
If Windows prevents the script from running because of the PowerShell execution policy, it can be started with:

powershell.exe -ExecutionPolicy Bypass -File ".\HP-Printer-Cleanup.ps1"
The script also uses -ExecutionPolicy Bypass when relaunching itself with Administrator privileges.

**Warning**
This script removes HP printers and HP printer drivers from the computer.

Use it only on systems where HP printer removal is intended.

The script searches using the terms HP and Hewlett-Packard. Because matching is name-based, verify that removing all matching printers and drivers is appropriate before using the script in a production environment.

Some drivers may fail to uninstall if they are still being used by Windows or another printer queue. These failures are displayed as warnings rather than causing the entire script to stop.

**Troubleshooting**
Driver cannot be removed
A driver may still be associated with another printer queue or be in use by the Print Spooler.

Check remaining drivers with:

Get-PrinterDriver
You can also check remaining printers with:

Get-Printer
Access Denied
Make sure the UAC elevation prompt was accepted and the PowerShell session is running as Administrator.

Script execution is disabled
Run:

powershell.exe -ExecutionPolicy Bypass -File ".\HP-Printer-Cleanup.ps1"

**Disclaimer**
This script is intended for IT administration and troubleshooting purposes. Test it in a controlled environment before deploying it broadly.

Use at your own risk. Review the script and verify that its matching and removal behavior is appropriate for your environment before running it on production devices.
