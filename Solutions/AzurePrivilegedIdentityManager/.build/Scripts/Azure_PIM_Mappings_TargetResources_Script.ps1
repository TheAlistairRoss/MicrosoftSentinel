# Written In PowerShell for ease. 
# Version 0.2

Set-Location "Solutions\AzurePrivilegedIdentityManager\"
$FilePath = '.build\Mappings\Azure_PIM_Mappings_TargetResources.csv'
$OutputPath = 'Parsers\Azure_PIM_Parser.txt'



Try {
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

$_Let_AzurePIMOperationsMappings = @'
let _AzurePIMOperationsMappings = dynamic(
    {

'@ + 
$ActivitiesMapping + @'
    }
); 
let _AzurePIMEvents = (){
    AuditLogs
    | where Category == "RoleManagement"
    | where OperationName in (bag_keys(_AzurePIMOperationsMappings))
    | extend ObjectIndexSet = _AzurePIMOperationsMappings.[OperationName].Object
    | extend RoleNameIndexSet = _AzurePIMOperationsMappings.[OperationName].RoleName
    | extend RoleIdIndexSet = _AzurePIMOperationsMappings.[OperationName].RoleId
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

$_Let_AzurePIMOperationsMappings | Out-File -FilePath $OutputPath -Force


