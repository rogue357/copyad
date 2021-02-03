These scripts will export the OU structure, users, groups and group memberships from one AD instance and import into another.

# Usage
Before you run these scripts [RSAT](https://www.microsoft.com/en-us/download/details.aspx?id=45520) must be installed on your computer(s).


## Export source AD
1. Modifty the variables:
   - $basedn
   - $oucsv
   - $groupscsv
   - $usercsv
   - $groupmembershipcsv 
    
  to match your environment.  
  
2. Run script on a Windows computer that is a member of the source domain as a user that can view the AD structure.  
   In most environments a normal AD user will suffice
   

## Import target AD
1. Copy exported files to a member machine in the target domain (usually the DC)

2. Modify the variables:
   - $OldDomain
   - $NewDomain
   - $OldMailDomain
   - $NewMailDomain
   - $oucsv
   - $userscsv
   - $groupscsv
   - $groupmembershipcsv 
    
  to match your environment
  
3. Run script as a user that has privlages to create objects on the domain.  Usually this will be as a domain admin

# Troubleshooting

## Fix for PowerShell Script Not Digitally Signed
You might receive the error *.ps1 is not digitally signed. The script will not execute on the system.* when you run the scripts.  To address this run the following command in the Powershell session:
```ps
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```
Note, this will only last for the current PowerShell session.  More information can be found [here](https://caiomsouza.medium.com/fix-for-powershell-script-not-digitally-signed-69f0ed518715)

## Install RSAT
You might run into several issues installing RSAT depending on how your organization has enabled WSUS.  [These](https://social.technet.microsoft.com/Forums/en-US/42bfdd6e-f191-4813-9142-5c86a2797c53/windows-10-1809-rsat-toolset-error-code-of-0x800f0954?forum=win10itprogeneral) [threads](https://social.technet.microsoft.com/Forums/ie/en-US/aaf22478-0b45-4517-be61-e2ab6c74f870/windows-10-1809-rsat-tools?forum=win10itprosetup) should help.


