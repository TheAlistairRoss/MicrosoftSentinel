# Testing 
#$RootDirectory = (Get-Location).path
#$solutionDirectory = "Solutions/CostManagement"
#$OutputFolder = "Prices_Test"
#$CurrencyCodes = "USD"
#$InformationPreference = "Continue"
#$Regions = "westus"
#$Services = "Azure Monitor"#, "Sentinel"


# Constants
$RootDirectory = $env:directory
$solutionDirectory = $env:solutionDirectory
$Location = Join-Path -Path $RootDirectory -ChildPath $solutionDirectory
$InformationPreference = $env:informationPreference
$OutputFolder = "Prices"
$Services = "Azure Monitor", "Sentinel"
$baseUrl = "https://prices.azure.com/api/retail/prices?api-version=2021-10-01-preview"
$CurrencyCodes = "USD", "AUD", "BRL", "CAD", "CHF", "CNY", "DKK", "EUR", "GBP", "INR", "JPY", "KRW", "NOK", "NZD", "RUB", "SEK", "TWD"
$Global:ScriptRunDateTime = get-date -AsUTC -UFormat "%Y/%m/%d %H:%M:%S"

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

$SentinelFilter = "&`$filter=" +
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
    "Azure Monitor" = $AzureMonitorFilter
    "Sentinel"      = $SentinelFilter
}

# classes

class PriceObject {

    [datetime]$TimeGenerated
    [string]$ServiceName
    [string]$ArmRegionName
    [ValidateSet("USD", "AUD", "BRL", "CAD", "CHF", "CNY", "DKK", "EUR", "GBP", "INR", "JPY", "KRW", "NOK", "NZD", "RUB", "SEK", "TWD")]
    [string]$CurrencyCode
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
        $this.$Tier
        $this.$UnitOfMeasure
        $this.$RetailPrice
        $this.$EffectiveStartDate
        $this.$EffectiveCommitmentTierThresholdGB,
        $this.$EffectivePricePerGB

    }
}

function Get-AzPricingRaw {
    param(
        $Url
    )

    $OriginalUrl = $Url
    $AzPricesRequest = [PriceObject[]]@()
    $ItemsReturned = 0
    $AzPricesRawRequest = [PriceObject[]]@()

    $TimeGenerated = if ($Global:ScriptRunDateTime) { 
        $Global:ScriptRunDateTime
    }else {
        get-date -AsUTC -UFormat "%Y-%m-%dT%H:%M:%S"
    }

    try {
        $EndLoop = $false
        do {

            $Request = Invoke-RestMethod -Method Get -Uri $Url
            $ItemsReturned += $Request.Count
            Write-Information "Items Returned: $ItemsReturned"

            if ($Request) {
                foreach ($RequestItem in $Request.Items){

                    if ($RequestItem.serviceName -eq "Log Analytics") {
                        $ServiceName = "Azure Monitor"
                    }else {
                        $ServiceName = $RequestItem.serviceName
                    }
                        $AzPriceRawRequest = New-Object -TypeName PriceObject -Property @{
                            TimeGenerated      = $TimeGenerated
                            ServiceName        = $ServiceName
                            ArmRegionName      = $RequestItem.armRegionName
                            CurrencyCode       = $RequestItem.currencyCode
                            Tier               = $RequestItem.meterName.split(" ")[0]
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
    $AzPricesRawRequestOutput = $AzPricesRawRequest | where {$_.RetailPrice -ne 0}
    return $AzPricesRawRequestOutput
}

# functions
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

    $EnrichedAzPricesRequest | Format-Table | Out-String | foreach {Write-Information $_}

    return $EnrichedAzPricesRequest
    
    Write-Host "$CmdletName`: Items Collected: $ItemsReturned"
    Write-Host "$CmdletName`: Complete"
}

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
        $AddedEffectivePricePerGB.EffectivePricePerGB = $InputObject.Tier / $InputObject.RetailPrice 
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
            $Object.EffectiveCommitmentTierThresholdGB = $Object.RetailPrice / $PreviousTierObject.EffectivePricePerGB 
        }
        $AddedEffectiveCommitmentTierThresholdGB += $Object         
    }
    return $AddedEffectiveCommitmentTierThresholdGB
}

function Add-PricingObjectDifferences {
    <#
    .SYNOPSIS
        Takes two PricingObject classes, determines the most recent for each tier in the Reference Object and compares the retail price to the Difference Object. If the retail price is different, then it returns the object
    #>
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

function Parse-DateTime {
    param(
        $DateTimeString
    )

    if ($DateTimeString.GetType() -ne [datetime]) {
        try {
            Write-Verbose "Parsing Exact DateTime: $DateTimeString"
            $DateTimeStringOutput = [datetime]::ParseExact($DateTimeString, "dd/MM/yyyy HH:mm:ss", $null) 
        }
        catch {
            Write-Error "Failed to Parse the DateTimeString '$DateTimeString'"
            break
        }
    }
    elseif($DateTimeString.GetType() -eq [datetime]) {
        Write-Verbose "Using Exisitng Time String: $DateTimeString"
        $DateTimeStringOutput = $DateTimeString
    } else {
        Write-Error "Failed To Process the DateTimeString"          
    }
    return $DateTimeStringOutput
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
                if ($Object.TimeGenerated.GetType() -ne [datetime]) {
                    try {
                        Write-Verbose "Parsing Exact DateTime: $($Object.TimeGenerated)"
                        $TimeGenerated = [datetime]::ParseExact($Object.TimeGenerated, "dd/MM/yyyy HH:mm:ss", $null) 
                    }
                    catch {
                        Write-Error "Failed to Parse the TimeGenerated '$($Object.TimeGenerated)'"
                        break
                    }
                }
                elseif($Object.TimeGenerated.GetType() -eq [datetime]) {
                    Write-Verbose "Using Exisitng Time: $($Object.TimeGenerated)"
                    $TimeGenerated = $Object.TimeGenerated
                } else {
                    Write-Error "Failed To Process the Field Time Generated"          
                }

                $ConvertedObject = New-Object -TypeName PriceObject
                
                $ConvertedObjectProperties = @{
                    TimeGenerated      = Parse-DateTime -DateTimeString $Object.TimeGenerated
                    ServiceName        = $Object.ServiceName
                    ArmRegionName      = $Object.ArmRegionName
                    CurrencyCode       = $Object.CurrencyCode
                    Tier               = $Object.Tier
                    UnitOfMeasure      = $Object.UnitOfMeasure
                    RetailPrice        = $Object.RetailPrice
                    EffectiveStartDate = Parse-DateTime -DateTimeString $Object.EffectiveStartDate
                    EffectiveCommitmentTierThresholdGB = $Object.EffectiveCommitmentTierThresholdGB
                    EffectivePricePerGB = $Object.EffectivePricePerGB
                } 
                
                $ConvertedObjectProperties | Format-Table | Out-String | foreach {Write-Verbose $_}
                foreach ($ConvertedObjectPropertyKey in $ConvertedObjectProperties.Keys){
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
                    $Compare = Compare-Object -ReferenceObject $OldRetailPrice.retailPrice -DifferenceObject $NewRetailPrice.retailPrice
                    if ($Compare) {
                        $PricingObjects += $NewRetailPrice 
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

    Set-Location $Location
    foreach ($Service in $Services) {
        foreach ($CurrencyCode in $CurrencyCodes) {
            Write-Host ""
            Write-Host "Processing Currency Code $CurrencyCode for $Service"
            $url = $baseUrl + "&currencyCode='$CurrencyCode'" + $Filters.$Service
    
            #Filter out zero prices, we aren't interested in free tiers for this
            $Prices = Get-AzPricing -Url $url 

            # Create Each file for each region. This will speed up the workbook.
            if (! $Regions){
                $Regions = $Prices | Select-Object -Unique -ExpandProperty armRegionName | Sort-Object 
            }

            foreach ($Region in $Regions) {
                $OutputPath = "$OutputFolder\$Service\$Region\$CurrencyCode`_Prices.csv"

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
                    $OutputToFile | Sort-Object TimeGenerated | Export-Csv -Path $OutputPath -Force
                }
                else {
                    Write-Host "No changes to be added to file : $OutputPath"
                } 
            }
        }
    } 
    Write-Host "End of script"
}

main


