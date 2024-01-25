> # Lab Setup

## Pre-requisites

1. **Creation of an Azure App Registration and Secret** - [Quickstart: Register an app in the Microsoft identity platform - Microsoft Entra | Microsoft Learn](https://learn.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app) - This can be created during or prior to the deployment. Ensure you note the following details
    1. TenantId
    1. Client (Application) Id
    1. Client Secret
1. **Resource Group with Owner Permissions** - This workshop requires a resource group which the user performing the deployment has owner or user access administrator. This is to apply role assignment for deployed resources and the App Registration.
1. **User Accounts** - Each user should be provisoned a user account in your Azure Tenant. 
1. **Security Group** - This will be used for assigning permissions to the users for the workshop

## **Phase 1 Deploy ARM Templates**

1. Deploy the ARM template:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FTheAlistairRoss%2FMicrosoftSentinel%2Fmain%2FLabs%2FAnalysts%2520Introduction%2520Workshop%2FBuild%2Fazuredeploy.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FTheAlistairRoss%2FMicrosoftSentinel%2Fmain%2FLabs%2FAnalysts%2520Introduction%2520Workshop%2FBuild%2FcreateUiDefinition.json)
     
   
1. Set the Parameters
   1. **Subscription** - Select the subscription where the resoruces will be deployed
   2. **Resource Group** - Select an exisiting or create a new resource group (recommended) for the workshop resources.    
   3. **Region** - This is automatically set based on your Resource Group location
   4. **Microsoft Sentinel Workspace Name** - Specify a new for the new workspace.
   3. **Workshop Name** - Leave as default (analyst-workshop)
   4. **Location** - Leave as default ([resourceGroup().location])
   5. **Analytic Rules** - Move the slider or enter a number to select the number of analytic rules to be created for the workshop. Minimum = 2, Maximum = 16
   6. **Microsoft Entra User Group Id** - This is the Object Id of the user group.
   7. **Service Principal** - Create a new or select an existing Service Principal (App Registration). The password field is not required in this template, but should be saved for the later script.
   
> **NOTE:** Ensure you get the outputs from the deployment. These contain values needed for the deployment script
1. Record the outputs from the script:
   1. **DCEIngestionEndpoint**: This is the Uri needed for ingesting custom data
   2. **DCRImmutableId**: This is the id of the data collection rule which the endpoint will forward the data to.  |

## Phase 3. Log Deployment

1. Copy the following PowerShell script to an editor of your choosing.

```powershell
$CustomDataIngestionScriptParams = @{
      DataCollectionEndpointUri = "<Your_Data_Collection_Endpoint_URI>"
      DataCollectionRuleImmutableId = "<Your_Data_Collection_Rule_Immutable_Id>"
      AppRegistrationId = "<Your_App_Registration_(Client)_Id>"
      AppRegistrationTenantId = "<Your_Tenant_Id>"
      AppRegistrationSecret = "<Your_App_Registration_Secret>"
      SourceFile = "CustomSigninLogs.csv"
}
$DataSetUri = "https://raw.githubusercontent.com/TheAlistairRoss/MicrosoftSentinel/main/Labs/Analysts%20Introduction%20Workshop/Build/CustomData/CustomSigninLogs.csv"
Invoke-RestMethod -Method Get -Uri $DataSetUri -OutFile "CustomSigninLogs.csv"

$scriptUri = "https://raw.githubusercontent.com/TheAlistairRoss/MicrosoftSentinel/main/Labs/Analysts%20Introduction%20Workshop/Build/Scripts/CustomDataIngestionScript.ps1"
Invoke-RestMethod -Uri $scriptUri | Out-File "CustomDataIngestionScript.ps1"

.\CustomDataIngestionScript.ps1 @CustomDataIngestionScriptParams 
```

2. Change the parameter values under the **$CustomDataIngestionScriptParams** hash table. The values to change look like *"<Your_Value>"*.

3. Open up a PowerShell terminal. This has been tested in the Azure Cloud Shell.

4. Paste the PowerShell script in and run the code. This should only take a minute or two as it is not a huge dataset.

> Note: If there are any issues running the script. Review the output, recitfy the issue and rerun again. For the purpose of this workshop, the ingested logs are minimal (less than 2000). The Time Generated field is automatically set to the previous day, so all will happen is log duplicate (with the ingestion time ) being different.

## Phase 4: Cleanup

Once the lab is complete, depending on how you have deployed, will depend on what needs to be removed.

1. If you have deployed to a isolated Resource group, where all resources within the resource group have been deployed as part of this lab

   1. Delete the resource group - [Delete resource group and resources - Azure Resource Manager | Microsoft Learn](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/delete-resource-group?tabs=azure-powershell#delete-resource-group)
   2. Delete the App Registration - [How to: Remove a registered app from the Microsoft identity platform - Microsoft Entra | Microsoft Learn](https://learn.microsoft.com/en-us/azure/active-directory/develop/howto-remove-app#remove-an-application-authored-by-you-or-your-organization)
2. If you have deployed to an existing Sentinel Environment. You will need to remove the following

   1. Azure Workbook - **Demo Azure AD Sign-in logs**
   2. Log Analytics function (Saved Search) - **fSigninLogs**
   3. Analytic Rules (For however many were deployed) - **Contoso Break Glass Account XX**
   4. Data Collection Rule -  **&lt;SentinelWorkspaceName&gt;-analyst-hunting-dcr**
   5. Data Collection Endpoint - **&lt;SentinelWorkspaceName&gt;-analyst-hunting-dce**
   6. Delete the App Registration - [How to: Remove a registered app from the Microsoft identity platform - Microsoft Entra | Microsoft Learn](https://learn.microsoft.com/en-us/azure/active-directory/develop/howto-remove-app#remove-an-application-authored-by-you-or-your-organization)
