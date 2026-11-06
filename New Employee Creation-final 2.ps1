

function Generate-RandomPassword {
    param (
        [int]$Length = 15
    )

    $UppercaseChars = 65..90 | ForEach-Object {[char]$_}
    $LowercaseChars = 97..122 | ForEach-Object {[char]$_}
    $SpecialChars = 33, 35, 36, 37, 38, 42, 64, 94, 95, 126 | ForEach-Object {[char]$_}

    $Password = @()

    # Add at least one character from each character set
    $Password += $UppercaseChars | Get-Random
    $Password += $LowercaseChars | Get-Random
    $Password += $SpecialChars | Get-Random

    # Generate the remaining characters randomly
    $RemainingLength = $Length - 3
    $AllChars = $UppercaseChars + $LowercaseChars + $SpecialChars
    $Password += $AllChars | Get-Random -Count $RemainingLength

    # Shuffle the password characters
    $Password = $Password | Sort-Object {Get-Random}

    return -join $Password
}

Function CheckUsername {
    param (
        [string]$Username
    )
    # Specify the username to check
    $targetUsername = $Username

    # Check if the username exists in Active Directory
    $userExists = Get-ADUser -Filter { SamAccountName -eq $targetUsername }

    # Output the result
    if ($userExists) {
        return $true
    } else {
        return $false
    }
}

# We need to make sure the username doesn't conflict with proxyaddresses on other users. 
# Conflicts can happen with our old name format or if a user has multiple aliases that don't match the original username
Function CheckSMTPUsername {
    param (
        [string]$Username
    )
    # Check for existing users with alternate SMTP address matching the username
    write-host "Checking proxy addresses for username conflicts: $Username"
    $existingUsers = Get-ADUser -Filter "proxyAddresses -like 'smtp:$Username@*'" -Properties proxyAddresses, sAMAccountName | Select-Object sAMAccountName
        
    if ($existingUsers) {
        Write-Host "Found existing user(s) with alternate SMTP address matching the username: $existingUsers"
        return $true
    }
    return $false
}

# Function to create an Active Directory user
function Create-ADUser {
    param (
        [string]$FirstName,
        [string]$LastName,
        [string]$MiddleName,
        [string]$EmployeeID,
        [string]$OU,
        [string]$Username
    )

    # Input checks
    if (-not $FirstName) {
        Write-Host "Error: First name cannot be empty."
        return
    }

    if (-not $LastName) {
        Write-Host "Error: Last name cannot be empty."
        return
    }

    # Set the password length
    $PasswordLength = 15

    # Generate a random password
    $Password = Generate-RandomPassword -Length $PasswordLength

    # Define the username
    if ( CheckUsername -Username $Username ) {
        write-host "ERROR: Username conflict: $Username cannot create"
        return $false
    }
    if ( CheckSMTPUsername -Username $Username ) { 
        write-host "ERROR: Proxy address conflict cannot create $Username"
        return $false
    }

    # Define main email address
    $EmailAddress = $Username + "@cfpork.com"

    # Construct the full name
    $FullName = "$FirstName $LastName"

    Write-Host "Creating $($FullName)"
    # Create the user
    try {
        New-ADUser -Server CFSE-DC04 `
    -SamAccountName $Username `
    -UserPrincipalName "$Username@christensenfarms.com" `
    -GivenName $FirstName `
    -Surname $LastName `
    -OtherName $MiddleName `
    -EmailAddress $EmailAddress `
    -EmployeeID $EmployeeID `
    -Name $FullName `
	-DisplayName $FullName `
    -Enabled $true `
    -AccountPassword (ConvertTo-SecureString -AsPlainText $Password -Force) `
    -Path $OU `
    -ChangePasswordAtLogon $true `
    -OtherAttributes @{
        mailNickname = $Username
        proxyAddresses = @(
            "SMTP:$Username@cfpork.com"
            "smtp:$Username@christensenfarms.com"
			"smtp:$Username@christensenfarms.onmicrosoft.com"
			"smtp:$Username@christensenfarms.mail.onmicrosoft.com"
        )
    }
    }  catch { 
        Write-Host "ERROR: Could not create user: $($Username) check you are running with the right permissions" 
        return $true
    } 

    # Write username-password pair to a CSV file
    $UserPasswordPair = [PSCustomObject]@{
        Username = $Username
        Password = $Password
    }
    $UserPasswordPair | Export-Csv -Append -Path "$($env:TEMP)\NewUser-output.csv" -NoTypeInformation


    return $true

}


#Function to manually enter employee information
function Enter-ManualInfo {
    # Specify the target OU in Active Directory
    $TargetOU = "OU=New,OU=Users,OU=Sleepy Eye,OU=Locations,DC=se,DC=christensenfarms,DC=com"

    $FirstName = Read-Host "Enter first name: "
    $MiddleName = Read-Host "Enter middle name: "
    $LastName = Read-Host "Enter last name: "
    $eid = Read-Host "Enter employee ID: "

    $Username = ($FirstName.Split(' ')[0]).Trim() + "." + ($LastName.Split(' ')[0]).Trim()
    if ( Create-ADUser -FirstName $FirstName -LastName $LastName -MiddleName $MiddleName -EmployeeID $eid.PadLeft(5,'0') -OU $TargetOU -Username $Username ) {
         # Successful   
    } else {
        #Failure creating
        $Username = ($FirstName.Split(' ')[0]).Trim() + "." + $MiddleName.Substring(0,1) + "." + ($LastName.Split(' ')[0]).Trim()
        $createdOk = Create-ADUser -FirstName $FirstName -LastName $LastName -MiddleName $MiddleName -EmployeeID $eid.PadLeft(5,'0') -OU $TargetOU -Username $Username
    }
}


# Main script
Write-Host "Employee Information Entry Script"
Write-Host "1. Enter information manually"
Write-Host "2. Exit"

$weDone = 0
while($weDone -ne 1) {
    $choice = Read-Host "Choose an option (1/2)"
    switch ($choice) {
        1 { 
            Enter-ManualInfo
            $weDone = 1
            Start-Process wordpad.exe $env:TEMP\NewUser-output.csv
         }
        2 { 
            exit 
        }
        default { Write-Host "Invalid choice. Please choose 1 or 2." }
    }
}



pause
