> # Lab Setup

## Pre-requisites

1. **Creation of an Azure App Registration and Secret** - [Quickstart: Register an app in the Microsoft identity platform - Microsoft Entra | Microsoft Learn](https://learn.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app)
2. **Resource Group with Owner Permissions** - This is needed as we will be deploying additional resources and assigning permissions.
3. **(Optional) Exisitng Sentinel Instance** - This would optional, as this template will deploy everything that is needed.

## **Phase 1 Deploy ARM Templates**

1. Deploy the ARM template:
   1. [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fthealistairross%2Fmicrosoftsentinel%2Fmain%2Flabs%2Fanalysts%2520introduction%2520workshop%2Fbuild%2Fazuredeploy.json)
   2. Deploy via PowerShell
2. Record the outputs from the script:
   1. **DCEIngestionEndpoint**: This is the Uri needed for ingesting custom data
   2. **DCRImmutableId**: This is the id of the data collection rule which the endpoint will forward the data to.

## Phase 2: Assign Permissions

1. Open the Azure Portal
2. Navigate to **Monitor**
3. Scroll down to **Data Collection Rules**
4. Find the Data collection rule (**YourSentinelName-analyst-hunting-dcr**)
5. Select **Access control**
6. Click **Add**, then **Add Role Assignment**
7. Select **Monitoring Metrics Publisher**, then click **Next**
8. Ensure that "Users, group or service principal" is selected, the click **+ Select members**
9. Find your App Registration, ensure it is selected, then click **Select**
10. Click **Review + assign**

## Phase 3: Generate Dummy Sign in Logs

1. Copy the files **CustomSigninLogs.csv** and **CustomDataIngestionScript.ps1** are copied locally to your device, or to the Azure Cloud Shell. For simplicity, ensure they are in the same directory
2. Edit the parameters then run the script. It is easier to do this beforehand in a text editor, such as visual studio code.

   ```powershell
   $CustomDataIngestionScriptParams =@{
       DataCollectionEndpointUri = "<Your_Data_Collection_Endpoint_URI>"
       DataCollectionRuleImmutableId = "<Your_Data_Collection_Rule_Immutable_Id>"
       AppRegistrationId = "<Your_App_Registration_(Client)_Id>"
       AppRegistrationTenantId = "<Your_Tenant_Id>"
       AppRegistrationSecret = "<Your_App_Registration_Secret>"
   }

   .\CustomDataIngestionScript.ps1 @CustomDataIngestionScriptParams

   ```
3. Change directory to the directory where the script and template are located
4. Run the script. This should only take a minute or two.

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
