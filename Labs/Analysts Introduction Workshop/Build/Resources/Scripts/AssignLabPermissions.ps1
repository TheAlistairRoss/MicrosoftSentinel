
param(
    [string]$ResourceGroupName,
    [string[]] $MonitoringMetricsPublishers,
    [string[]] $SentinelResponder,
    [string[]] $SentinelAutomationContributor
)

function Set-AzRoleAssignment{
    param(
        $ObjectId, $RoleDefinitionName, $ResourceGroupName
    )

    Write-Host "Checking Role '$RoleDefinitionName' for ObjectId '$ObjectId' against Resource Group '$ResourceGroupName'"
    $ExistingRoleAssignment = Get-AzRoleAssignment -ObjectId $ObjectId -ResourceGroupName $ResourceGroupName -RoleDefinitionName $RoleDefinitionName

    if ($ExistingRoleAssignment){
        Write-Host "Role Already Exists"
    }else{
        Write-Host "Assigning Role"
        try{
            New-AzRoleAssignment -ObjectId $ObjectId -ResourceGroupName $ResourceGroupName -RoleDefinitionName $RoleDefinitionName -ErrorAction Stop |Out-Null
        }
        catch{
            Write-Error "Failed to Assign Permissions. Review the error and run again or assign manually"
        }
    }
}

foreach ($ObjectId in $MonitoringMetricsPublishers){
    Set-AzRoleAssignment -ObjectId $ObjectId -RoleDefinitionName "Monitoring Metrics Publisher" -ResourceGroupName $ResourceGroupName 
}

foreach ($ObjectId in $SentinelResponder){
    Set-AzRoleAssignment -ObjectId $ObjectId -RoleDefinitionName "Microsoft Sentinel Responder" -ResourceGroupName $ResourceGroupName 
}

$AzureSecurityInsightsAppId = "98785600-1bb7-4fb9-b9fa-19afe2c8a360"
$AzureSecurityInsightsApp = Get-AzADservicePrincipal -ApplicationId $AzureSecurityInsightsAppId
Set-AzRoleAssignment -ObjectId $AzureSecurityInsightsApp.Id -RoleDefinitionName "Microsoft Sentinel Automation Contributor" -ResourceGroupName $ResourceGroupName


start-sleep 30
Write-Host "Completed" -ForegroundColor White -BackgroundColor Green

