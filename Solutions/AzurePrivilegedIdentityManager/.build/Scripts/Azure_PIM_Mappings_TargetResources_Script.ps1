# Written In PowerShell for ease. 
# Version 0.2

Set-Location "Solutions\AzurePrivilegedIdentityManager\"
$FilePath = '.build\Mappings\Azure_PIM_Mappings_TargetResources.csv'
$OutputPath = 'Parsers\Azure_PIM_Parser.txt'

# Constants
$ParserARMTemplatePath = ".\.build\Templates\resources\Microsoft.OperationalInsights\workspaces\savedSearches.json"
$ParserARMTemplate = ".\.build\Templates\resources\Microsoft.OperationalInsights\workspaces\savedSearches.json"
$RGDeploymentARMTemplate = ".\.build\Templates\Deployments\ResourceGroupDeployment.json"




try {
    $CSV = Import-CSV -Path $FilePath -ErrorAction Stop
}
catch {
    Write-Error "Failed to import CSV ($FilePath)"
    $Error[-1]
    exit
}

$ActivitiesMapping = ""
$Index = 1
foreach ($Row in $CSV) {
    $Activity = "`"$($Row.OperationName)`": {`"RoleId`":$($Row.RoleId),`"Object`":$($Row.Object),`"RoleName`":$($Row.RoleName)}"
    if ($Index -eq $CSV.Count){
        $ActivityOutput = "`t`t$Activity`r`n"
    }
    else{
        $ActivityOutput = "`t`t$Activity,`r`n"
    }
    Write-Host "$($Index): $ActivityOutput"

    $ActivitiesMapping += $ActivityOutput
    $Index ++
}


# Build Operations Mapping parser resource
$AzurePIMOperationsMappings_Parser_Alias = "_AzurePIMOperationsMappings"
$AzurePIMOperationsMappings_Parser = @'
let 
'@ + $AzurePIMOperationsMappings_Parser_Alias + @'
 = dynamic(
    {

'@ + 
$ActivitiesMapping + @'
    }
); 
'@

$AzurePIMOperationsMappings_Resource = Get-Content -Path $ParserARMTemplatePath 
| ConvertFrom-Json -Depth 5


$AzurePIMOperationsMappings_Resource | Add-Member -NotePropertyMembers @{
    name = "Azure Privileged Identity Manager Parsed Events"
    dependsOn = @(
        "[resourceId('Microsoft.OperationalInsights/workspaces', parameters('workspace'))]"
    )
    properties = @{
        displayName = "Azure Privileged Identity Manager Parsed Events"
        category = "Log Management"
        functionAlias = $AzurePIMOperationsMappings_Parser_Alias
        query = $AzurePIMOperationsMappings_Parser
        version = "0.1"
    }
} -Force


#
$AzurePIMEvents_Parser_Alias = "_AzurePIMEvents"
$AzurePIMEvents_Parser = @'
let
'@ + $AzurePIMEvents_Parser_Alias + @'
 = (){
    AuditLogs
    | where Category == "RoleManagement"
    | where OperationName in (bag_keys('@
'@ + $AzurePIMOperationsMappings_Parser_Alias + @'
))
    | extend ObjectIndexSet = 
'@ + $AzurePIMOperationsMappings_Parser_Alias + @'
.[OperationName].Object
    | extend RoleNameIndexSet = 
'@ + $AzurePIMOperationsMappings_Parser_Alias + @'
    .[OperationName].RoleName
    | extend RoleIdIndexSet = 
'@ + $AzurePIMOperationsMappings_Parser_Alias + @'
    .[OperationName].RoleId
    | extend ObjectId = tostring(TargetResources[toint(ObjectIndexSet[0])].id)
    | extend Object = case(
        (array_length(ObjectIndexSet) <= 0), "", 
        array_length(ObjectIndexSet) == 1, case(
            isnotempty(tostring(TargetResources[toint(ObjectIndexSet[0])].userPrincipalName)), tostring(TargetResources[toint(ObjectIndexSet[0])].userPrincipalName),
            tostring(TargetResources[toint(ObjectIndexSet[0])].displayName)
        ),
        "Unknown Mapping"
    )
    | extend Object = case((Object startswith replace_string(ObjectId,"-","")), substring(Object, strlen(replace_string(ObjectId,"-",""))), Object)
    | extend ObjectType = tostring(TargetResources[toint(ObjectIndexSet[0])].type)
    | extend Role = case(
        array_length(RoleNameIndexSet) == 1, trim(@'^\"|\"$', tostring(TargetResources[toint(RoleNameIndexSet[0])].displayName)),
        array_length(RoleNameIndexSet) == 3, trim(@'^\"|\"$', tostring(TargetResources[toint(RoleNameIndexSet[0])].modifiedProperties.[toint(RoleNameIndexSet[1])].[tostring(RoleNameIndexSet[2])])),
        "Unknown Mapping"
        )
    | extend RoleId = case(
        array_length(RoleIdIndexSet) == 1, trim(@'^\"|\"$', tostring(TargetResources[toint(RoleIdIndexSet[0])].id)),
        array_length(RoleIdIndexSet) == 3, trim(@'^\"|\"$', tostring(TargetResources[toint(RoleIdIndexSet[0])].modifiedProperties.[toint(RoleIdIndexSet[1])].[tostring(RoleIdIndexSet[2])])),
        "Unknown Mapping"
    )
    | extend InitiatedByType = tostring(bag_keys(parse_json(InitiatedBy))[0])
    | extend InitiatedByObject = case(
        (InitiatedByType == "user"), case(
            isnotempty(tostring(parse_json(InitiatedBy.user.userPrincipalName))), tostring(parse_json(InitiatedBy.user.userPrincipalName)), 
            tostring(parse_json(InitiatedBy.user.displayName))
        ),
        (InitiatedByType == "app"), tostring(parse_json(InitiatedBy.app.displayName)),
        "Unknown Mapping"
    )
    | extend InitiatedByObjectId = case(
        (InitiatedByType == "user"), tostring(parse_json(InitiatedBy.user.id)),
        (InitiatedByType == "app"), tostring(parse_json(InitiatedBy.app.servicePrincipalId)),
        "Unknown Mapping"
    )
};
'@

$AzurePIMEvents_Resource | Add-Member -NotePropertyMembers @{
    name = "Azure Privileged Identity Manager Parsed Events"
    dependsOn = @(
        "[resourceId('Microsoft.OperationalInsights/workspaces', parameters('workspace'))]"
    )
    properties = @{
        displayName = "Azure Privileged Identity Manager Parsed Events"
        category = "Log Management"
        functionAlias = $AzurePIMOperationsMappings_Parser_Alias
        query = $AzurePIMOperationsMappings_Parser
        version = "0.1"
    }
} -Force






