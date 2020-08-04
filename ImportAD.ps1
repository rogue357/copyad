# Script to Import a copy of an AD instance
# This will import the OU structure, Groups, Users, and Group Membership
# It will not copy users passwords and accounts will be created disabled
# It will also not copy group policies, etc.
#
# Inspired by the copyAD suite found on technet authored by Greg Martin gmartin@gmartin.org
# 
# Modify the variables to match the instance being copied
#

#Import-Module ActiveDirectory -ErrorAction SilentlyContinue  



# Imports a list of OUs 
function ImportOU ($OldDomain, $NewDomain, $incsv) {
	

	$good = 0
	$oops = 0

	#We have to run this loop multiple times because
	#OU imports are not ordered so some will error because the parent
	#Is not created.
	#Loop will run into all imports error out
	do {

		$oulist = import-csv $incsv
		$oulist |foreach { 
	    $outemp = $_.Distinguishedname -replace $OldDomain,$NewDomain
	        #need to split ouTemp and lose the first item
	    $ousplit = $outemp -split ',',2
	    $outemp
	    try {    
	        $newOU = New-ADOrganizationalUnit -name $_.Name -path $ousplit[1] -EA stop
	        Write-Host "Created: $_.Name"
	        $good++
	    }
	    Catch {
	        Write-host "Error creating OU: $outemp"  #$error[0].exception.message"
	        $oops++
	     }
	     Finally {
	            echo ""
	     }
	        
	    }
	    Write-host "Created $good OUs with $oops errors"
        $good = 0
	    $oops = 0

	} until ($good -eq 0)

}

# Imports a list of users
# Note that many system properties are removed from this list; the manager field cannot 
# be copied over unless care is taken to create the manager accts before others and to 
# fixup the managerdn before import.
function ImportUsers($OldDomain, $NewDomain, $OldMailDomain,$NewMailDomain, $incsv) {
	
	$oops = 0
	$good = 0


	$userlist = import-csv $incsv
	$userlist |foreach { 
	    #fixup UPN by replacing yourco.com with yourtest.com
	    $_.UserPrincipalName = $_.UserPrincipalName -replace , $OldMailDomain, $NewMailDomain
	        
	    #fixup DN by replacing original domain components with new ones 
	    $_.Distinguishedname = $_.Distinguishedname -replace , $OldDomain, $NewDomain
	    
	    # Path is DN minus the first field (cn=username)
	    # RegEX handles scanarios where the CN is Last, First and can't
	    # just split on the first comma
	    $Path = $_.Distinguishedname -split '(?<!\\),',2
	    $Name = $_.Name
	    try {
	        $_|New-ADUser -Path $Path[1] -EA Stop
	        Write-Host "Created: $Name"
	        $good++
	    }
	    Catch {
	        Write-host "Error creating user: $Name"
	        $oops++
	    }
	    Finally {
	        write-host ""
	    }
	    #Enable-ADUser $newuser
	    }
	Write-host "Created $good users with $oops errors"


}

# Imports a list of groups
function ImportGroups($OldDomain, $NewDomain, $incsv) {
	
	$oops = 0
	$good = 0

	$grouplist = import-csv $incsv 
	$grouplist |foreach { 
	    #fixup DN by replacing original domain components with new ones 
	    $_.Distinguishedname = $_.Distinguishedname -replace , $OldDomain, $NewDomain

	    # Path is DN minus the first field (cn=username)
	    $Path = $_.Distinguishedname -split ',',2
	    $tName = $_.Name
	    Write-Host "Creating: "$tName""
	    try {    
	        $newgroup = $_|New-ADgroup -Path $Path[1] -EA Stop
	        Write-Host "Created: "$tName""
	        $good++
	    }
	    Catch {
	        Write-host "Error creating group: "$tName""
	        $oops++
	     }
	     Finally {
	            echo ""
	     }
	}
	Write-host "Imported "$good" groups with "$oops" errors"

}

# Imports user group memberships
function ImportGroupMemberships($OldDomain, $NewDomain, $incsv) {

	$oops = 0
	$good = 0

	$membrlist = import-csv $incsv
	$membrlist |foreach { 
	        
	    #fixup DN by replacing original domain components with new ones 
	    $tgroup = $_.groupdn -replace , $OldDomain, $NewDomain
	    $tUser =  $_.Username
	    Write-Host "Adding: "$tUser" to "$tgroup""
	    try {    
	        get-ADUser -identity $tUser -EA stop| Add-ADPrincipalGroupMembership -memberof $tgroup -EA Stop -WA SilentlyContinue
	        Write-Host "Added: "$tUser" to: "$tgroup""
	        $good++
	    }
	    Catch {
	        Write-host "Error adding:"$tUser" to: "$tgroup""
	        $oops++
	     }
	     Finally {
	            echo ""
	     }
	}
	Write-host "Imported "$good" memberships; saw "$oops" errors"

}

#Import the multivalued attributes
function ImportMVAttributes($OldDomain, $NewDomain, $incsv) {

	
    $mvattrs = import-csv $incsv
    $mvattrs |foreach { 

        Write-Host "Adding value $value to attribute $attribute for $username"

        $username = $_.username 
	    $attribute =  $_.attribute
        $value = $_.value

        try {
            Get-ADUser $username -Properties * | Set-ADUser -Add @{$attribute = $value}
        }
        Catch {
            Write-Host "Error Adding value $value to attribute $attribute for $username"
        }
        

    }


}



#Source domain
$OldDomain = 'dc=sourcedomain,dc=local' 
#Target domain 
$NewDomain = 'dc=targetdomain,dc=local' 
#Old email domain / principal name
$OldMailDomain = 'sourcedomain.local'
#New email domain / principal name
$NewMailDomain = 'targetdomain.local'

#Exported OU structure
$oucsv = 'C:\vagrant\OUexport.csv'
#Exported Users
$userscsv = "C:\vagrant\users.csv"
#Exported Groups
$groupscsv = 'C:\vagrant\groups.csv'
#Exported Group Memberhips
$groupmembershipscsv = 'C:\vagrant\grpmemberships.csv'
#Exported ProxyAddresses
$mvattributescsv = 'C:\vagrant\\mvattributes.csv'

#Import OU Structure
ImportOU $OldDomain $NewDomain $oucsv

#Import Users
ImportUsers $OldDomain $NewDomain $OldMailDomain $NewMailDomain $userscsv

#Import Groups
ImportGroups $OldDomain $NewDomain $groupscsv

#Import Group Memberhips
ImportGroupMemberships $OldDomain $NewDomain $groupmembershipscsv

#Import Proxy Addresses
ImportMVAttributes $OldDomain $NewDomain $mvattributescsv
