These scripts will export the OU structure, users, groups and group memberships from one AD instance and import into another.

Usage

Export source AD
1) Modifty the variables:
    $basedn
    $oucsv
    $groupscsv
    $usercsv
    $groupmembershipcsv 
    
  to match your environment.  
  
2) Run script on a Windows computer that is a member of the source domain as a user that can view the AD structure.  
   In most environments a normal AD user will suffice
   

Import target AD
1) Copy exported files to a member machine in the target domain (usually the DC)

2) Modify the variables:
    $OldDomain
    $NewDomain
    $OldMailDomain
    $NewMailDomain
    $oucsv
    $userscsv
    $groupscsv
    $groupmembershipcsv 
    
  to match your environment
  
3) Run script as a user that has privlages to create objects on the domain.  Usually this will be as a domain admin


