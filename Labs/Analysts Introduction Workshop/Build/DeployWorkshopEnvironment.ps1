param(
    # Sentinel Workspace Resource Id
    [Parameter(Mandatory=$true)]
    [ValidatePattern("(\/.*){5}microsoft.operationalinsights\/workspaces\/.*$")]
    $workspaceResourceId,

    # This is the number of the first user Id. For example admin1046 would be 1046
    [int]
    [Parameter(Mandatory=$true)]   
    $firstUserId,

    # Number of Users (between 1 and 16)
    [int]
    [ValidateRange(1,40)]
    $numberOfUsers  = 1
)
# Validate Workspace
$WorkspaceRegEx = "(\/.*){5}microsoft.operationalinsights\/workspaces\/.*$"
if ($workspaceResourceId -notmatch $WorkspaceRegEx){
    Write-Error -Message "Invalid Workspace Id.. Ensure it matches the pattern '/subscriptions/<SubscriptionId>/resourcegroups/<ResourceGroupName>/providers/microsoft.operationalinsigts/workspaces/<WorkspaceName>"
    exit
}
#Constants
$SignInLogsTemplate = $PSScriptRoot + "\standardUserLoginAnalyticRule-template.json"
$SubscriptionId = $workspaceResourceId.split("/")[2]
$ResourceGroupName = $workspaceResourceId.split("/")[4]
$WorkspaceName = $workspaceResourceId.split("/")[8]

# Login

$Context = Get-AzContext
if ($Context.Subscription.Id -ne $SubscriptionId){
    try {
        Write-Verbose "Setting Azure Context to : '$SubscriptionId'"
        Set-AzContext -SubscriptionId $SubscriptionId -ErrorAction Stop
    }
    catch {
        Write-Warning "No existing connection found. Connecting to Azure'"
        Connect-AzAccount -SubscriptionId $SubscriptionId -ErrorAction Stop
    }
}

# Validate Sentinel Access
# Deploy Templates

$Deployment = "Sentinel-$(Get-Date -Format 'yyyyMMdd_ssmmHH')"
$TemplateParameters =@{
    workspace = $WorkspaceName
    firstUserId = $firstUserId
    numberOfAccounts = $numberOfUsers
}

New-AzResourceGroupDeployment -Name $Deployment -TemplateFile $SignInLogsTemplate -ResourceGroupName $ResourceGroupName @TemplateParameters

# Generate Data

Write-Host "Waiting 1 minute before generating Logs"
Start-Sleep -Seconds 60
$i = 0
$Run = 0
$TotalRuns = 6 * $numberOfUsers
$Start = Get-Date
$End = $Start.AddHours(1)
do {
    $PercentComplete = (100/$TotalRuns) * $Run
    Write-Progress -Activity "Generating Bad login attempt for: $UserName" -Status "$Run of $TotalRuns" -PercentComplete $PercentComplete 
    $AccountNumber = $firstUserId + $i
    $UserName = "standard" + $AccountNumber + "@sentinellab.xyz"
    $WrongPassword = "Password123" | ConvertTo-SecureString -AsPlainText -Force
    
    $Credential = [pscredential]::new($UserName, $WrongPassword)
    #Write-Host "Generating Bad login attempt for '$UserName"
    Start-Sleep -Seconds 2
    Connect-AzAccount -Credential $Credential -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    
    $Run ++
    $i++
    if ($i -gt $numberOfUsers){
        $i = 0
    }
} until (
    $End -le (Get-Date) -or $Run -eq (3 * $numberOfUsers)
)
Write-Progress -Activity "Bad Logins Complete" -Status "$Run of $TotalRuns" -PercentComplete 100


