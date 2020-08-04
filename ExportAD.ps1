# Script to Export a copy of an AD instance
# This will copy the OU structure, Groups, Users, and Group Membership
# It will not copy users passwords and accounts will be created disabled
# It will also not copy group policies, etc.
# 
# Modify the variables to match the instance being copied
#
#Import-Module ActiveDirectory -ErrorAction SilentlyContinue  

# Exports a list of OUs generated with this command
function ExportOU ($outcsv) {

    get-AdorganizationalUnit -filter * | export-csv $outcsv 

}

# Exports selected Group attributes to a csv file
function ExportGroups ($basedn, $outcsv) {
   
    get-adgroup -filter * -searchbase $basedn -properties * |select DistinguishedName,GroupCategory,GroupScope,Name,SamAccountName,Description |export-csv $outcsv

}

# Exports selected user attributes to a csv file.  This are only single valued attributes
function ExportUsers ($basedn, $adAttributes, $outcsv) {
  
    get-aduser -filter * -searchbase $basedn -properties * |select ($adAttributes -split ',') | export-csv $outcsv

}

# Export a list of users and group memberships
# Export file is csv with samaccountname and Group DN
function ExportGroupMembership ($basedn, $outcsv) {

    $mbrcnt = 0
    $usrcnt = 0
    $memberships = @()
    $mem= new-object object
    $mem |add-member noteproperty username "samaccountname"
    $mem |add-member noteproperty groupdn "group"
    get-aduser -filter * -searchbase $basedn -property memberof| foreach {
        $usrcnt++
        $sam = $_.samaccountname
        foreach ($group in $_.memberof) {
           $mbrcnt++
           $mem= new-object object
	       $mem |add-member noteproperty username $sam
	       $mem |add-member noteproperty groupdn $group
           $memberships += $mem
           }
       
        }
    $memberships |export-csv $outcsv
    write-host "$mbrcnt group memberships exported for $usrcnt users"

}

# Export the passed in multivalued attributes
function ExportMVAttributes($adMVAttributes, $basedn, $outcsv) {
   

   $values = @()
   $mem= new-object object
   $mem |add-member noteproperty username "samaccountname"
   $mem |add-member noteproperty attribute "attribute"
   $mem |add-member noteproperty value "value"

   get-aduser -filter * -searchbase $basedn -property * | select ($adMVAttributes -split ',') | foreach {

    $sam = $_.samaccountname

    $properties = % {$_.psobject.properties}
    
    foreach($property in $properties){
    
        $attribute = $property.name
        #Skip SamAccountName
        if( $attribute -eq "SamAccountName") { continue }
        
        foreach($value in $property.value) {

            $mem= new-object object
            $mem |add-member noteproperty username $sam
            $mem |add-member noteproperty attribute $attribute
            $mem |add-member noteproperty value $value
            $values += $mem


        }


    } 

   }
    
   $values |export-csv $outcsv
    

}


#AD Attributes to export
$adAttributes = "CanonicalName,City,CN,codePage,Company,Country,countryCode,Department,DisplayName,DistinguishedName,Division,EmailAddress,EmployeeID,EmployeeNumber,Fax,GivenName,HomeDirectory,HomeDrive,HomePage,HomePhone,info,Initials,mail,MobilePhone,Name,Office,OfficePhone,Organization,OtherName,physicalDeliveryOfficeName,POBox,ProfilePath,SamAccountName,ScriptPath,State,StreetAddress,Surname,Title,UserPrincipalName"
$adMVAttributes = "SamAccountName,Description,extensionAttribute1,extensionAttribute2,extensionAttribute3,extensionAttribute4,extensionAttribute5,extensionAttribute6,extensionAttribute7,extensionAttribute8,extensionAttribute9,extensionAttribute10,extensionAttribute11,extensionAttribute12,extensionAttribute13,extensionAttribute14,extensionAttribute15,mailNickname,PostalCode,proxyAddresses"


#BaseDN of the instance being copied
$basedn = 'dc=sourcedomain,dc=local'

#Location to export the OU structure
$oucsv = 'c:\vagrant\OUexport.csv'

#Location to export the groups
$groupscsv = 'c:\vagrant\groups.csv'

#Location to export the users
$usercsv = 'c:\vagrant\users.csv'

#Location to export the group memberships
$groupmembershipcsv = "c:\vagrant\grpmemberships.csv" 

#Location to export proxyAddresses
$mvattributescsv = "c:\vagrant\mvattributes.csv" 


ExportOU $oucsv
ExportGroups $basedn $groupscsv
ExportUsers  $basedn $adAttributes $usercsv
ExportGroupMembership $basedn $groupmembershipcsv
ExportMVAttributes $adMVAttributes $basedn $mvattributescsv
