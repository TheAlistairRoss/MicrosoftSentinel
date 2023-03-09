Write-Host "Prices are calculated based on US dollars and converted using Thomson Reuters benchmark rates refreshed on the first day of each calendar month" -ForegroundColor Yellow


# Constants
$RootDirectory = $env:directory
$solutionDirectory = $env:solutionDirectory
$InformationPreference = $env:informationPreference
$OutputFolder = "Prices"
$Services = "Azure Monitor", "Sentinel"
$baseUrl = "https://prices.azure.com/api/retail/prices?api-version=2021-10-01-preview"
$CurrencyCodes = "USD", "AUD", "BRL", "CAD", "CHF", "CNY", "DKK", "EUR", "GBP", "INR", "JPY", "KRW", "NOK", "NZD", "RUB", "SEK", "TWD"
$Global:ScriptRunDateTime = get-date -AsUTC -UFormat "%Y/%m/%d %H:%M:%S"

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
    "Sentinel" = $SentinelFilter
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

    PriceObject() {}

    PriceObject (
        [datetime]$TimeGenerated,
        [string]$ServiceName,
        [string]$ArmRegionName,
        [string]$CurrencyCode,
        [string]$Tier,
        [string]$UnitOfMeasure,
        [decimal]$RetailPrice,
        [datetime]$EffectiveStartDate
    ) {
        $this.$TimeGenerated
        $this.$ServiceName
        $this.$ArmRegionName
        $this.$CurrencyCode
        $this.$Tier
        $this.$UnitOfMeasure
        $this.$RetailPrice
        $this.$EffectiveStartDate
    }
}

# functions
function Get-AzPricing {
    [cmdletbinding()]
    param(
        $Url
    )
    $CmdletName = "Get-AzPricing"
    Write-Information "$CmdletName`: -Url $url"

    $TimeGenerated = if ($Global:ScriptRunDateTime) { 
        $Global:ScriptRunDateTime
    }
    else {
        get-date -AsUTC -UFormat "%Y-%m-%dT%H:%M:%S"
    }

    $Output = @()
    $ItemsReturned = 0
    try {
        do {

            $Request = Invoke-RestMethod -Method Get -Uri $Url
            $ItemsReturned += $Request.Count
            Write-Information "$CmdletName`: Items Returned: $ItemsReturned"

            if ($Request) {
                $Request.Items | ForEach-Object {

                    if ($_.serviceName -eq "Log Analytics") {
                        $ServiceName = "Azure Monitor"
                    }
                    else {
                        $ServiceName = $_.serviceName
                    }
                    $Output += New-Object -TypeName PriceObject -Property @{
                        TimeGenerated      = $TimeGenerated
                        ServiceName        = $ServiceName
                        ArmRegionName      = $_.armRegionName
                        CurrencyCode       = $_.currencyCode
                        Tier               = $_.meterName.split(" ")[0]
                        UnitOfMeasure      = $_.unitOfMeasure
                        RetailPrice        = $_.retailPrice
                        EffectiveStartDate = $_.effectiveStartDate
                    } 
                }
            }              
            
            $Url = $Request.NextPageLink

            $i ++
        } until (
            !$Request.NextPageLink
        )
    }
    catch {
        Write-Error -Message "$CmdletName`: Failed to execute command"
        exit
    }
    
    if ($Service -eq "Azure Monitor") {
        # Consolidate the Service Name for Log Analytics and Azure Monitor
        Write-Host "Converting 'Log Analytics' serviceName to 'Azure Monitor'"
        $Prices.Where({ $_.ServiceName -eq "Log Analytics" }) | ForEach-Object {
            $_.ServiceName = "Azure Monitor"
        }
    }

    return $Output
    Write-Host "$CmdletName`: Items Collected: $ItemsReturned"

    Write-Host "$CmdletName`: Complete"
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

function ConvertTo-PriceObject {
    param (
        [parameter(
            ValueFromPipeline = $true
        )]
        [object[]]$InputObject
    )
   
    process {
        try {
    
            foreach ($Object in $InputObject) {
                if ($InputObject.TimeGenerated.GetType() -ne [datetime]) {
                    try {
                        $TimeGenerated = [datetime]::ParseExact($InputObject.TimeGenerated, "dd/MM/yyyy HH:mm:ss", $null) 
                    }
                    catch {
                        Write-Error "Failed to Parse the TimeGenerated '$($InputObject.TimeGenerated)'"
                        break
                    }
                }
                else {
                    $TimeGenerated = $InputObject.TimeGenerated
                }

                New-Object -TypeName PriceObject -Property @{
                    TimeGenerated      = $TimeGenerated
                    ServiceName        = $InputObject.ServiceName
                    ArmRegionName      = $InputObject.ArmRegionName
                    CurrencyCode       = $InputObject.CurrencyCode
                    Tier               = $InputObject.Tier
                    UnitOfMeasure      = $InputObject.UnitOfMeasure
                    RetailPrice        = $InputObject.RetailPrice
                    EffectiveStartDate = $InputObject.EffectiveStartDate
                } -ErrorAction Stop
            }
        }
        catch {
            Write-Error "Failed to process object"
        }
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
        $Output = @()
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
                        $Output += $NewRetailPrice
                    }
                }

            }
            else {
                $Output = $DifferenceObject
            }
        }
        return $Output

    }
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

function main {

    Set-Location $RootDirectory\$solutionDirectory
    foreach ($Service in $Services) {
        foreach ($CurrencyCode in $CurrencyCodes) {
            Write-Host ""
            Write-Host "Processing Currency Code $CurrencyCode for $Service"
            $url = $baseUrl + "&currencyCode='$CurrencyCode'&" + $Filters.$Service
    
            #Filter out zero prices, we aren't interested in free tiers for this
            $Prices = Get-AzPricing -Url $url | Where-Object { $_.retailPrice -ne 0 }

            # Create Each file for each region. This will speed up the workbook.
            $Regions = $Prices | Select-Object -Unique -ExpandProperty armRegionName | Sort-Object 
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
