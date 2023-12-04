# Chats and Hacks 2023 - Linux to Sentinel with DCR filtering and splitting workshop

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FTheAlistairRoss%2FMicrosoftSentinel%2Fmain%2FLabs%2FLog%2520Collection%2520and%2520Splitting%2520Workshop%2520-%2520Chats%2520and%2520Hacks%25202023%2FBuild%2Fmain.json
)




### Table Creation PowerShell Script

```powershell
$resourceGroupName = "sent-chats-and-hacks-workshop-sentinel-rg"
$workspaceName = "sent-chats-and-hacks-workshop-wksp"
$oldTableName = "CommonSecurityLog"
$newTableName = "CommonSecurityLog_CL"
$baseUrl = "https://management.azure.com"

$workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $resourceGroupName -Name $workspaceName
$Table = Get-AzOperationalInsightsTable -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -TableName $oldTableName

$TableSchemaColumns = $Table.Schema.StandardColumns | where Name -ne "TenantId"
$TableProperties = @{
        properties = @{
        schema = @{
            name = $newTableName
            columns = $TableSchemaColumns
        }
        plan = "Basic"
    }
} | ConvertTo-Json -Depth 10

$url = $baseUrl + $workspace.ResourceId + "/tables/" + $newTableName + "?api-version=2022-10-01"
Invoke-AzRestMethod -Uri $url -Method Put -Payload $TableProperties

```