
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