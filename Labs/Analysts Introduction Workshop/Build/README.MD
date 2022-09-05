# Lab Setup

#### Pre-requisites

1. Microsoft Sentinel Workspace created
2. Azure AD Sign In Logs data connector enabled
3. Sentinel Contributor Permissions 

#### Deploy Analytics and Generate Logs

1. Make sure the **DeployWorkshopEnvironment.ps1** script and **standardUserLoginAnalyticRule-template.json** ARM template to the same directory on your local machine
2. Open up PowerShell with the AZ modules installed.
3. Change directory to the directory where the script and template are located
4. Connect to the Azure AD tenant where your workspace resides with:
```powershell
Connect-AzAccount
```
5. Run the following 
 ```powershell
.\deployWorkshopEnvironment.ps1 `
    -workspaceResourceId $WorkspaceResourceID ` # Workspace Resource Id where the analytics rules will be deployed
    -firstUserId 1 ` # Starting User ID
    -numberOfUsers 20 ` # Number of users within the range.
    -Verbose
```
