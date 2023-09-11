<#
.SYNOPSIS
    This script Gets the publically avaliable pricing details related to Microsoft Sentinel'
.DESCRIPTION
    This scrpt gets the publically avaliable pricing details for related to Log Ingestion and Analysis for Microsoft Sentinel. 
    It does this by gathering the ingestion and commitment tier details for Log Analytics and the classic analysis and commitment tiers for Microsoft Sentinel.
    It performs calculations to determine the cost effective volume to move commitment tier and the effective price per GB. 
    Once calculated, it writes the data to a file path in CSV format.
.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'
.LINK
    https://github.com/TheAlistairRoss/MicrosoftSentinel/tree/CostManagementV2/Solutions/CostManagement
.EXAMPLE
    GetMicrosoftSentinelRetailPrices.ps1
    Gets all the data and ingest the logs into a local file. The Root Directory and Solution Directory parameters are passed in as Environment variables. Useful when running as a pipeline
.EXAMPLE
    GetMicrosoftSentinelRetailPrices.ps1 -RootDirectory "C:/Users/TheAlistairRoss/" -SolutionsDirectory "/Solutions/CostManagement"
    Gets all the data and ingest the logs into a local file. The Root Directory and Solution Directory parameters are passed in as strings to allow the script to be run in a different location to the output.
#>

[CmdletBinding()]
param (
    [string]
    $RootDirectory,
    [string]
    $SolutionDirectory,

    [Parameter(Mandatory = $true)]
    [ValidateSet("Classic", "Unified")]
    [string]
    $PricingModel
)

# Constants
if (!$RootDirectory) {
    $RootDirectory = $env:directory
}
if (!$SolutionDirectory) {
    $SolutionDirectory = $env:solutionDirectory
}
$Location = Join-Path -Path $RootDirectory -ChildPath $solutionDirectory
$InformationPreference = $env:informationPreference

$baseUrl = "https://prices.azure.com/api/retail/prices?api-version=2021-10-01-preview"
$CurrencyCodes = "USD", "AUD", "BRL", "CAD", "CHF", "CNY", "DKK", "EUR", "GBP", "INR", "JPY", "KRW", "NOK", "NZD", "RUB", "SEK", "TWD"

$PreviousTierHash = @{
    "100"  = "Pay-as-you-go"
    "200"  = 100
    "300"  = 200
    "400"  = 300
    "500"  = 400
    "1000" = 500
    "2000" = 1000
    "5000" = 2000
}

$AzureMonitorFilter = "&`$filter=" +
"(" +
"serviceName eq 'Azure Monitor'" +
" or serviceName eq 'Log Analytics'" +
")" +
" and (" +
"meterName eq 'Pay-as-you-go Data Ingestion'" +
" or meterName eq '100 GB Commitment Tier Capacity Reservation'" +
" or meterName eq '200 GB Commitment Tier Capacity Reservation'" +
" or meterName eq '300 GB Commitment Tier Capacity Reservation'" +
" or meterName eq '400 GB Commitment Tier Capacity Reservation'" +
" or meterName eq '500 GB Commitment Tier Capacity Reservation'" +
" or meterName eq '1000 GB Commitment Tier Capacity Reservation'" +
" or meterName eq '2000 GB Commitment Tier Capacity Reservation'" +
" or meterName eq '5000 GB Commitment Tier Capacity Reservation'" +
")" 

$ClassicSentinelFilter = "&`$filter=" +
"(" +
"serviceName eq 'Sentinel'" +
")" +
" and (" +
"meterName eq 'Classic Pay-as-you-go Analysis'" +
" or meterName eq 'Classic 100 GB Commitment Tier Capacity Reservation'" +
" or meterName eq 'Classic 200 GB Commitment Tier Capacity Reservation'" +
" or meterName eq 'Classic 300 GB Commitment Tier Capacity Reservation'" +
" or meterName eq 'Classic 400 GB Commitment Tier Capacity Reservation'" +
" or meterName eq 'Classic 500 GB Commitment Tier Capacity Reservation'" +
" or meterName eq 'Classic 1000 GB Commitment Tier Capacity Reservation'" +
" or meterName eq 'Classic 2000 GB Commitment Tier Capacity Reservation'" +
" or meterName eq 'Classic 5000 GB Commitment Tier Capacity Reservation'" +
")" 

$UnifiedSentinelFilter = "&`$filter=" +
"(" +
"serviceName eq 'Sentinel'" +
")" +
" and (" +
"meterName eq 'Pay-as-you-go Analysis'" +
" or meterName eq '100 GB Commitment Tier Capacity Reservation'" +
" or meterName eq '200 GB Commitment Tier Capacity Reservation'" +
" or meterName eq '300 GB Commitment Tier Capacity Reservation'" +
" or meterName eq '400 GB Commitment Tier Capacity Reservation'" +
" or meterName eq '500 GB Commitment Tier Capacity Reservation'" +
" or meterName eq '1000 GB Commitment Tier Capacity Reservation'" +
" or meterName eq '2000 GB Commitment Tier Capacity Reservation'" +
" or meterName eq '5000 GB Commitment Tier Capacity Reservation'" +
")" 

$Filters = @{
    "Azure Monitor"     = @{
        Name = "Azure Monitor"
        oDataFilter = $AzureMonitorFilter
    }
    "Classic Sentinel"  = @{
        Name = "Sentinel"
        oDataFilter = $ClassicSentinelFilter
    }
    "Unified Sentinel"  = @{
        Name = "Sentinel"
        oDataFilter = $UnifiedSentinelFilter
    }
}

# classes

class PriceObject {

    [datetime]$TimeGenerated
    [string]$ServiceName
    [string]$ArmRegionName
    [ValidateSet("USD", "AUD", "BRL", "CAD", "CHF", "CNY", "DKK", "EUR", "GBP", "INR", "JPY", "KRW", "NOK", "NZD", "RUB", "SEK", "TWD")]
    [string]$CurrencyCode
    [string]$MeterName
    [string]$Tier
    [string]$UnitOfMeasure
    [decimal]$RetailPrice 
    [datetime]$EffectiveStartDate
    [decimal]$EffectiveCommitmentTierThresholdGB
    [decimal]$EffectivePricePerGB

    PriceObject() {}

    PriceObject (
        [datetime]$TimeGenerated,
        [string]$ServiceName,
        [string]$ArmRegionName,
        [string]$CurrencyCode,
        [string]$MeterName,
        [string]$Tier,
        [string]$UnitOfMeasure,
        [decimal]$RetailPrice,
        [datetime]$EffectiveStartDate,
        [decimal]$EffectiveCommitmentTierThresholdGB,
        [decimal]$EffectivePricePerGB
    ) {
        $this.$TimeGenerated
        $this.$ServiceName
        $this.$ArmRegionName
        $this.$CurrencyCode
        $this.$MeterName
        $this.$Tier
        $this.$UnitOfMeasure
        $this.$RetailPrice
        $this.$EffectiveStartDate
        $this.$EffectiveCommitmentTierThresholdGB,
        $this.$EffectivePricePerGB
    }
}

# functions

function Get-FormattedDate {
    param(
        [Parameter(ValueFromPipeline = $true,
            ValueFromRemainingArguments = $true)]
        [datetime]$DateTime
    )

    if ($DateTime) {
        $Output = $DateTime | Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
    }
    else {
        $Output = Get-Date -AsUTC -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
    }
    return $Output
}

# Gets the Data from the Azure Pricing API and converts it to a PricingObject Class
function Get-AzPricingRaw {
    param(
        $Url
    )

    $OriginalUrl = $Url
    #$AzPricesRequest = [PriceObject[]]@()
    $ItemsReturned = 0
    $AzPricesRawRequest = [PriceObject[]]@()

    if ($Global:ScriptRunDateTime) { 
        $TimeGenerated = $Global:ScriptRunDateTime
    }
    else {
        $TimeGenerated = Get-Date
    }

    try {
        $EndLoop = $false
        do {

            $Request = Invoke-RestMethod -Method Get -Uri $Url
            $ItemsReturned += $Request.Count
            Write-Information "Items Returned: $ItemsReturned"

            if ($Request) {
                foreach ($RequestItem in $Request.Items) {

                    if ($RequestItem.serviceName -eq "Log Analytics") {
                        $ServiceName = "Azure Monitor"
                    }
                    else {
                        $ServiceName = $RequestItem.serviceName
                    }

                    # Set Tier
                    if ($RequestItem.meterName -like "Classic Pay-as-you-go*") {
                        $Tier = "Pay-as-you-go"
                    }
                    elseif ($RequestItem.meterName -like "Classic*") {
                        $Tier = $RequestItem.meterName.Split(" ")[1]
                    }
                    else {
                        $Tier = $RequestItem.meterName.Split(" ")[0]

                    }

                    $AzPriceRawRequest = New-Object -TypeName PriceObject -Property @{
                        TimeGenerated      = $TimeGenerated
                        ServiceName        = $ServiceName
                        ArmRegionName      = $RequestItem.armRegionName
                        CurrencyCode       = $RequestItem.currencyCode
                        MeterName          = $RequestItem.meterName
                        Tier               = $Tier
                        UnitOfMeasure      = $RequestItem.unitOfMeasure
                        RetailPrice        = $RequestItem.retailPrice
                        EffectiveStartDate = $RequestItem.effectiveStartDate
                    }
                    $AzPricesRawRequest += $AzPriceRawRequest 
                }
            }              
            
            if ($Request.NextPageLink) {
                $Url = $Request.NextPageLink
            }
            elseif ($Request.Count -eq 100) {

                $Url = $OriginalUrl + '&$skip=' + $ItemsReturned
            }
            else {
                $EndLoop = $true
            }

            $i ++
        } until (
            $EndLoop -eq $true -or $Request.Count -lt 100
        )
    }
    catch {
        Write-Error $Error[0]
        Write-Error -Message "Failed to execute command"
        break
    }
    $AzPricesRawRequestOutput = $AzPricesRawRequest | where { $_.RetailPrice -ne 0 }
    return $AzPricesRawRequestOutput
}

# Runs the enrichement cmdlets for the Azure prices
function Add-AzPricingEffectiveCommitmentTierValues {
    param(
        [object[]]$InputObject
    )

    $EffectiveCommitmentTierValues = [PriceObject[]]@()
    $Regions = $InputObject | Group-Object -Property armRegionName
    
    foreach ($Region in $Regions) {
        $ObjectsByRegion = [PriceObject[]]@()

        foreach ($RegionPrice in $Region.Group) { 
            $ObjectsByRegion += Add-AzPricingEffectivePricePerGB -InputObject $RegionPrice
        }
    
        $EffectiveCommitmentTierValues += Add-AzPricingEffectiveCommitmentTierThresholdGB -InputObject $ObjectsByRegion
    }
    return $EffectiveCommitmentTierValues
}

function Add-AzPricingEffectivePricePerGB {
    param(
        [object]$InputObject
    )
    $AddedEffectivePricePerGB = $InputObject
    # Set the Effective Price Per GB Rate
    if ($InputObject.Tier -eq "Pay-as-you-go") {    
        $AddedEffectivePricePerGB.EffectivePricePerGB = $InputObject.RetailPrice
    }
    else {
        $EffectivePricePerGB = $InputObject.RetailPrice / $InputObject.Tier
        $EffectivePricePerGB = [math]::Round($EffectivePricePerGB , 4)
        $AddedEffectivePricePerGB.EffectivePricePerGB = $EffectivePricePerGB
    }
    return $AddedEffectivePricePerGB
}

function Add-AzPricingEffectiveCommitmentTierThresholdGB {
    param(
        [object[]]$InputObject
    )

    $AddedEffectiveCommitmentTierThresholdGB = [PriceObject[]]@()

    foreach ($Object in $InputObject) {
        # Set the GB value which it is finacially viable to move up to the next tier
        $PreviousTierObject = $InputObject.Where({ $_.Tier -eq $PreviousTierHash.($Object.Tier) })
        if ($PreviousTierObject) {
            $EffectiveCommitmentTierThresholdGB = $Object.RetailPrice / $PreviousTierObject.EffectivePricePerGB 
            $EffectiveCommitmentTierThresholdGB = [math]::Round($EffectiveCommitmentTierThresholdGB, 4)
            $Object.EffectiveCommitmentTierThresholdGB = $EffectiveCommitmentTierThresholdGB 
        }
        $AddedEffectiveCommitmentTierThresholdGB += $Object         
    }
    return $AddedEffectiveCommitmentTierThresholdGB
}

function Get-AzPricing {
    [cmdletbinding()]
    param(
        $Url
    )
    $CmdletName = "Get-AzPricing"
    Write-Information "$CmdletName`: -Url $url"

    $AzPricesRequest = Get-AzPricingRaw -Url $URL

    Write-Information "Enriching Pricing Values"
    $EnrichedAzPricesRequest = Add-AzPricingEffectiveCommitmentTierValues -InputObject $AzPricesRequest

    $EnrichedAzPricesRequest | Format-Table | Out-String | foreach { Write-Information $_ }

    return $EnrichedAzPricesRequest
    
    Write-Host "$CmdletName`: Items Collected: $ItemsReturned"
    Write-Host "$CmdletName`: Complete"
}

function Add-PricingObjectDifferences {
    param (
        [cmdletbinding()]
        [object[]]$ReferenceObject,
        [object[]]$DifferenceObject
    )

    process {
        $Compared = Compare-PricingObjects -ReferenceObject $ReferenceObject -DifferenceObject $DifferenceObject

        if ($ReferenceObject) {
            $Output = $ReferenceObject + $Compared | Sort-Object TimeGenerated, RetailPrice
        }
        else {
            $Output = $Compared | Sort-Object TimeGenerated, RetailPrice
        }
        
        return $Output
    }
}

function ConvertTo-PriceObject {
    param (
        [parameter(
            ValueFromPipeline = $true
        )]
        [object[]]$InputObject
    )

    process {
        $ConvertedObjects = [PriceObject[]]@()

        try {
            foreach ($Object in $InputObject) {

                $TimeGenerated = $Object.TimeGenerated | Get-Date
                $EffectiveStartDate = $Object.EffectiveStartDate | Get-Date
                $ConvertedObject = New-Object -TypeName PriceObject
                
                $ConvertedObjectProperties = @{
                    TimeGenerated                      = $TimeGenerated
                    ServiceName                        = $Object.ServiceName
                    ArmRegionName                      = $Object.ArmRegionName
                    CurrencyCode                       = $Object.CurrencyCode
                    MeterName                          = $Object.MeterName
                    Tier                               = $Object.Tier
                    UnitOfMeasure                      = $Object.UnitOfMeasure
                    RetailPrice                        = $Object.RetailPrice
                    EffectiveStartDate                 = $EffectiveStartDate
                    EffectiveCommitmentTierThresholdGB = $Object.EffectiveCommitmentTierThresholdGB
                    EffectivePricePerGB                = $Object.EffectivePricePerGB
                } 
                
                $ConvertedObjectProperties | Format-Table | Out-String | ForEach-Object { Write-Verbose $_ }
                foreach ($ConvertedObjectPropertyKey in $ConvertedObjectProperties.Keys) {
                    $ConvertedObject.$ConvertedObjectPropertyKey = $ConvertedObjectProperties.$ConvertedObjectPropertyKey
                }
                
                $ConvertedObjects += $ConvertedObject
            }
        }
        catch {
            Write-Error $Error[0]
        }
        return $ConvertedObjects
    }
}

function Compare-PricingObjects {
    <#
    .SYNOPSIS
        Takes two PricingObject classes, determines the most recent for each tier in the Reference Object and compares the retail price to the Difference Object. If the retail price is different, then it returns the object from the Difference Object only
    #>
    param (
        [cmdletbinding()]
        [object[]]$ReferenceObject,
        [object[]]$DifferenceObject
    )

    process {
        $PricingObjects = [PriceObject[]]@()
        if ($ReferenceObject -and $DifferenceObject) {
            if ($ReferenceObject) {
                Write-Information "Comparing Old and New Retail Prices"
                $OldRetailPrices = $ReferenceObject | Group-Object -Property Tier | ForEach-Object {
                    $_.Group | Sort-Object TimeGenerated -Descending | Select-Object -First 1
                }

                foreach ($OldRetailPrice in $OldRetailPrices) {
                    # Compare each price
                    $NewRetailPrice = $DifferenceObject.Where({ $_.Tier -eq $OldRetailPrice.Tier })
                    try {
                        $Compare = Compare-Object -ReferenceObject $OldRetailPrice.retailPrice -DifferenceObject $NewRetailPrice.retailPrice
                        if ($Compare) {
                            $PricingObjects += $NewRetailPrice 
                        }
                    }
                    catch {
                        Write-Error "Failed to Compare Retail prices."

                        Write-Host "Displaying ReferenceObject"
                        $ReferenceObject | Format-Table

                        Write-Host "Displaying DifferenceObject"
                        $DifferenceObject | Format-Table
                    }
                }

            }
            else {
                $PricingObjects = $DifferenceObject
            }
        }
        return $PricingObjects

    }
}

function New-File {
    [CmdletBinding()]
    param($Path)
    Write-Information "New-File: -path $OutputPath"

    try {
        Get-Item -Path $Path -ErrorAction Stop
        Write-Information "New-File: Path Exists"
    }
    catch {
        try {
            Write-Information "New-File: No file found. Creating file."
            New-Item -Path $path -Force -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Error "Failed to create file: $Path"
        }
    }
}

function main {

    $StartLocation = Get-Location
    Set-Location $Location
    $Global:ScriptRunDateTime = Get-FormattedDate

    if ($PricingModel -eq "Classic"){
        Write-Information "Setting Pricing Model to Classic"
        $OutputFolder = "Prices/Classic"
        $Services = @("Azure Monitor", "Classic Sentinel")
    } 
    elseif ($PricingModel -eq "Unified") {
        Write-Information "Setting Pricing Model to Unified"
        $OutputFolder = "Prices/Unified"
        $Services = @("Unified Sentinel")
    }
    else{
        Write-Error "No pricing model selected. Choose either '-Classic' or '-Unified' parameters when running the script"
        exit
    }

    foreach ($Service in $Services) {
        foreach ($CurrencyCode in $CurrencyCodes) {
            Write-Host ""
            Write-Host "Processing Currency Code $CurrencyCode for $Service"
            $url = $baseUrl + "&currencyCode='$CurrencyCode'" + $Filters.$Service.oDatafilter
    
            #Filter out zero prices, we aren't interested in free tiers for this
            $Prices = Get-AzPricing -Url $url 

            # Create Each file for each region. This will speed up the workbook.
            $Regions = $Prices | Select-Object -Unique -ExpandProperty armRegionName | Sort-Object 
            
            foreach ($Region in $Regions) {
                $OutputPath = "$OutputFolder\$($Filters.$Service.Name)\$Region\$CurrencyCode`_Prices.csv"

                New-File -Path $OutputPath

                # Get Existing Content
                $RegionPrices = $Prices.where({ $_.armRegionName -like $Region })

                $ExistingContent = Import-CSV -Path $OutputPath | ConvertTo-PriceObject
           
                if ($ExistingContent) {
                    Write-Host "Comparing Prices from $OutputPath"
                    $OutputToFile = Add-PricingObjectDifferences -ReferenceObject $ExistingContent -DifferenceObject $RegionPrices
                }
                else {
                    Write-Host "File Empty, Importing initial data. File: $OutputPath"
                    $OutputToFile = $RegionPrices
                }

                if ($OutputToFile.Count -gt $ExistingContent.Count) {
                    $NewItemCount = $OutputToFile.Count - $ExistingContent.Count
                    Write-Host "$NewItemCount prices added to file: $OutputPath"
                    $OutputToFile | Sort-Object TimeGenerated, RetailPrice | 
                    Select-Object  @{Name = 'TimeGenerated'; Expression = { Get-FormattedDate -DateTime $_.TimeGenerated } },
                    ServiceName,
                    ArmRegionName,
                    CurrencyCode,
                    MeterName,
                    Tier,
                    UnitOfMeasure,
                    RetailPrice,
                    @{Name = 'EffectiveStartDate'; Expression = { Get-FormattedDate -DateTime $_.EffectiveStartDate } },
                    EffectiveCommitmentTierThresholdGB,
                    EffectivePricePerGB
                    | Export-CSV -Path $OutputPath -Force
                }
                else {
                    Write-Host "No changes to be added to file : $OutputPath"
                } 
            }
        }
    } 
    $StartLocation | Set-Location
    Write-Host "End of script"
}

main


