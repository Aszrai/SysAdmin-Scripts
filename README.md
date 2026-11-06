
# Active Directory Employee Creation Script

A PowerShell utility that creates new employee accounts in Active Directory using manually entered employee information.

The script generates a username, checks for existing Active Directory and proxy address conflicts, creates the account in a designated organizational unit, generates a temporary password, and exports the new credentials to a CSV file.

## Features

- Prompts for employee information
- Generates a username using the employee's first and last name
- Checks for existing `sAMAccountName` conflicts
- Checks `proxyAddresses` for email alias conflicts
- Uses an alternate username containing the middle initial when necessary
- Generates a randomized 15-character password
- Creates the Active Directory account in a designated OU
- Assigns the user's email addresses and aliases
- Requires the user to change their password at the next sign-in
- Exports the username and temporary password to a CSV file
- Opens the CSV after account creation

## Requirements

- Windows PowerShell
- Active Directory PowerShell module
- Access to the target Active Directory domain
- Permission to create users in the target OU
- Permission to read Active Directory users and proxy addresses
- Network connectivity to the specified domain controller
- An authorized administrative workstation

The Active Directory module can be loaded with:

```powershell
Import-Module ActiveDirectory
```

To confirm the module is available:

```powershell
Get-Module -ListAvailable ActiveDirectory
```

## Employee Information Collected

The script prompts the technician to enter:

- First name
- Middle name
- Last name
- Employee ID

The employee ID is padded with leading zeros until it contains at least five characters.

For example:

```text
Entered employee ID: 123
Stored employee ID: 00123
```

## Username Generation

The script initially creates the username using the following format:

```text
firstname.lastname
```

For example:

```text
John.Smith
```

If that username already exists or conflicts with an existing SMTP proxy address, the script attempts to use the employee's middle initial:

```text
firstname.m.lastname
```

For example:

```text
John.A.Smith
```

## Username Conflict Checks

Before the account is created, the script performs two checks.

### Active Directory Username Check

The script searches for an existing Active Directory account with the same `sAMAccountName`:

```powershell
Get-ADUser -Filter { SamAccountName -eq $targetUsername }
```

If a matching account is found, the username is considered unavailable.

### Proxy Address Check

The script also checks whether the proposed username is already being used as an SMTP alias:

```powershell
Get-ADUser `
    -Filter "proxyAddresses -like 'smtp:$Username@*'" `
    -Properties proxyAddresses, sAMAccountName
```

This prevents conflicts with users who have an email alias that does not match their current username.

## Password Generation

The script generates a randomized 15-character temporary password.

Each generated password contains at least:

- One uppercase letter
- One lowercase letter
- One special character

The remaining characters are randomly selected from the available character sets, and the completed password is shuffled.

The special-character set includes:

```text
! # $ % & * @ ^ _ ~
```

> The current password generator does not include numeric characters.

## Active Directory Account Configuration

The script creates the account with the following settings:

| Attribute | Value |
|---|---|
| Account status | Enabled |
| Password length | 15 characters |
| Password change | Required at next sign-in |
| Display name | First name and last name |
| Employee ID | Manually entered and padded to five characters |
| Mail nickname | Generated username |
| Organizational unit | Configured target OU |
| UPN | Generated username with the configured UPN suffix |
| Primary email | Generated username with the configured email domain |

## Proxy Addresses

The account is assigned one primary SMTP address and multiple email aliases.

The uppercase `SMTP:` prefix identifies the primary email address:

```powershell
"SMTP:$Username@primary-domain.example"
```

Lowercase `smtp:` prefixes identify email aliases:

```powershell
"smtp:$Username@alternate-domain.example"
"smtp:$Username@tenant.onmicrosoft.com"
"smtp:$Username@tenant.mail.onmicrosoft.com"
```

## Usage

### 1. Save the script

Save the script as a PowerShell file:

```text
Create-ADUser.ps1
```

### 2. Open PowerShell

Open PowerShell from an authorized administrative workstation.

If your environment requires elevation, select **Run as administrator**.

### 3. Navigate to the script

```powershell
cd "C:\Path\To\Script"
```

### 4. Run the script

```powershell
.\Create-ADUser.ps1
```

If script execution is blocked by the current execution policy, run:

```powershell
powershell.exe -ExecutionPolicy Bypass -File ".\Create-ADUser.ps1"
```

### 5. Select an option

The script displays:

```text
Employee Information Entry Script
1. Enter information manually
2. Exit
```

Enter `1` to create a user or `2` to close the script.

### 6. Enter employee information

Example:

```text
Enter first name: John
Enter middle name: Andrew
Enter last name: Smith
Enter employee ID: 12345
```

The script then checks for username conflicts and attempts to create the account.

## Output File

After successful account creation, the generated username and temporary password are appended to:

```text
%TEMP%\NewUser-output.csv
```

The CSV contains the following columns:

```csv
Username,Password
John.Smith,TemporaryPassword
```

The script attempts to open this file after the account creation process finishes.

## Example Console Output

```text
Employee Information Entry Script
1. Enter information manually
2. Exit

Choose an option (1/2): 1
Enter first name: John
Enter middle name: Andrew
Enter last name: Smith
Enter employee ID: 12345

Checking proxy addresses for username conflicts: John.Smith
Creating John Smith
```

If a username conflict is found:

```text
ERROR: Username conflict: John.Smith cannot create
```

The script then attempts the middle-initial format:

```text
John.A.Smith
```

## Security Warning

> This script creates enabled Active Directory accounts and exports temporary passwords in plain text.

The CSV output should be handled carefully because anyone with access to the file can view the credentials.

Recommended precautions include:

- Run the script only from an authorized administrative workstation
- Restrict access to the script and output file
- Transfer credentials using an approved secure method
- Delete the CSV after the credentials have been delivered
- Do not commit credential output files to GitHub
- Do not store real domain names, domain controllers, or internal OU paths in a public repository
- Review account details before distributing credentials
- Keep `ChangePasswordAtLogon` enabled

Add the output file to `.gitignore`:

```gitignore
NewUser-output.csv
*.csv
```

## Important Limitations

### Middle Name Is Required for the Alternate Username

If the original username conflicts, the script uses:

```powershell
$MiddleName.Substring(0,1)
```

If no middle name was entered, this operation can fail.

### Existing Output Is Appended

The script uses:

```powershell
Export-Csv -Append
```

Previous account credentials remain in the output file until it is manually deleted.

### Plain-Text Password Storage

The generated temporary password is written directly to a CSV file. The file is not encrypted.

### Limited Username Collision Handling

The script attempts only two username formats:

1. `firstname.lastname`
2. `firstname.middleinitial.lastname`

If both formats are unavailable, the account is not created.

### Name Sanitization

The script does not currently normalize characters such as:

- Apostrophes
- Hyphens
- Spaces
- Accented characters
- Other special characters

These characters may produce usernames that do not match the organization's account naming requirements.

### Password Character Selection

The password generator uses `Get-Random`. For environments requiring cryptographically secure password generation, consider using a .NET cryptographic random number generator instead.

### WordPad Availability

The script attempts to open the output file using:

```powershell
Start-Process wordpad.exe
```

WordPad has been removed from newer Windows versions. Consider replacing it with:

```powershell
Invoke-Item "$env:TEMP\NewUser-output.csv"
```

This opens the CSV using the computer's default application.

## Recommended Improvements

- Validate that a middle name exists before creating the alternate username
- Add numeric characters to generated passwords
- Use a cryptographically secure password generator
- Remove or encrypt the credential CSV after use
- Confirm that `New-ADUser` succeeded before treating the operation as successful
- Check whether the employee ID already exists
- Normalize names before generating usernames
- Support additional username formats when both initial formats conflict
- Move environment-specific settings into a configuration file
- Replace WordPad with `Invoke-Item`
- Add structured logging without recording passwords
- Add a confirmation screen before creating the account

## Suggested Repository Structure

```text
AD-Employee-Creation/
├── Create-ADUser.ps1
├── README.md
├── .gitignore
└── LICENSE
```

## Disclaimer

This script is intended for authorized IT administration in a controlled Active Directory environment.

Test the script in a non-production environment before deploying it. Review the configured domain controller, OU path, UPN suffixes, and proxy address domains before running it.

The repository owner is not responsible for unauthorized account creation, exposed credentials, incorrect directory attributes, or changes made in a production environment.
