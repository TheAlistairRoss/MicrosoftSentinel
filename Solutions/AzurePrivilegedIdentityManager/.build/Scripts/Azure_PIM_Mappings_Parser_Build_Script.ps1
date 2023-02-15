# Written In PowerShell for ease. 
# This Parser is built from a CSV file, and therefore easier to maintain changes to the CSV with a build script
# Any changes to the CSV will result in a minor version increase by 1
# If changing the script, or any significant details, update the $Version variable at the start of this script
# Script Version 1.0

# Constants. These are the default values of the parser.
$ParserTitle = "Azure PIM Operations Mapping"
$ParserAlias = "AzurePIMOperationsMappings"
[version]$Version = '1.0'
#LastUpdated
$ProductName = "Azure Priviliged Identity Manager"
$Description = @"
This parser provides a datatable with the known Azure Priviliged Identity Manager operations from the Azure Active Directory AuditLog table.
"@


Set-Location "Solutions\AzurePrivilegedIdentityManager\"
$CSVFilePath = '.build\Mappings\Azure_PIM_Mappings_TargetResources.csv'
$OutputPath = "Parsers\$ParserAlias.yaml"

if (Get-Module -ListAvailable -Name powershell-yaml) {
    Write-Verbose "Module already installed"
}
else {
    Write-Host "Installing PowerShell-YAML module"
    try {
        Install-Module powershell-yaml -AllowClobber -Force -ErrorAction Stop
        Import-Module powershell-yaml
    }
    catch {
        Write-Error $_.Exception.Message
        break
    }
}

try {
    $CSV = Import-CSV -Path $CSVFilePath -ErrorAction Stop
}
catch {
    Write-Error "Failed to import CSV '$CSVFilePath'"
    $Error[-1]
    exit
}

function New-ParserTemplate {
    param($Title, $ParserAlias, $Version, $LastUpdated, $ProductName, $Description, $ParserQuery)
    
    $Template = [ordered]@{
        Parser = [ordered]@{
            Title = $Title
            Version = $Version
            LastUpdated = $LastUpdated
        }
        Product = @{
            Name = $ProductName
        }
        Description = $Description
        ParserName = $ParserAlias
        ParserParams =[ordered] @{
            Name = "disabled"
            Type = "bool"
            Default = "false"
        }
        ParserQuery = $ParserQuery
    }

    return $Template
}      

$ActivitiesMapping = ""
$Index = 1
foreach ($Row in $CSV) {
    $Activity = "`"$($Row.OperationName)`",`"$($Row.Category)`", dynamic($($Row.RoleIdIndexSet)), dynamic($($Row.ObjectIndexSet)), dynamic($($Row.RoleNameIndexSet)), `"$($Row.OperationDescription)`""
    if ($Index -eq $CSV.Count) {
        $ActivityOutput = "`t$Activity`r`n"
    }
    else {
        $ActivityOutput = "`t$Activity,`r`n"
    }
    Write-Host "$($Index): $ActivityOutput"

    $ActivitiesMapping += $ActivityOutput
    $Index ++
}

# Build Operations Mapping parser resource
$ParserQuery = @'
// This Parser is a work in progress by Alistair Ross (aliross@microsoft.com)
// Feel free to contribute at https://github.com/TheAlistairRoss/MicrosoftSentinel/tree/main/Solutions/AzurePrivilegedIdentityManager
datatable (OperationName: string, Category: string, RoleIdIndexSet: dynamic, ObjectIndexSet: dynamic, RoleNameIndexSet: dynamic, OperationDescription: string) [

'@ + 
$ActivitiesMapping + @'
]
'@

$OutputFile = Get-Item -Path  $OutputPath -ErrorAction Stop

if ($OutputFile){

    Write-Host "Exisitng Parser Found. Comparing Contents"
    # Exisiting Content, get the old file for comparison.
    # TrimEnd() required due to whitespace added in the files and the ConvertTo-Yaml cmdlet
    $OldParserContent = (Get-Content -Path $OutputFile -Raw).TrimEnd()
    $OldParserContentObject = $OldParserContent | ConvertFrom-Yaml -Ordered
    
    # Creating New Parser Object, though keeping old date and version for comparison
    $ParserParams = @{
        Title = $ParserTitle
        ParserAlias = $ParserAlias
        Version = $OldParserContentObject.Parser.Version
        LastUpdated = $OldParserContentObject.Parser.LastUpdated
        ProductName = $ProductName
        Description = $Description
        ParserQuery = $ParserQuery   
    }
    
    $Parser = New-ParserTemplate @ParserParams
    # TrimEnd() required due to whitespace added in the files and the ConvertTo-Yaml cmdlet
    $ParserYaml = ($Parser | ConvertTo-Yaml).TrimEnd()

    # Comparing Exisiting File to new file.
    $Compare = Compare-Object -ReferenceObject $OldParserContent -DifferenceObject $ParserYaml 

    # If there is a difference, update the file
    if ($Compare){
        Write-Host "Changed found between Exisitng Parser and New Parser, Updating Parser"
        # Increment Minor Version by 1 and change date
        $OldVersion = [version]$OldParserContentObject.Parser.Version
        $NewVersion = [version]::new($OldVersion.Major, $OldVersion.Minor +1)
        # If the $Version Variable at the start of the script is greater than the minor change, use it instead
        Write-Host "Comparing Versions"
        if ($Version -gt $NewVersion){
            Write-Host "Version Variable > File Version. Using setting version to $Version"
            $NewVersion = $Version
        }

        $LastUpdated = get-date -Format 'MMM dd yyy'

        $ParserParams.Version = $NewVersion.ToString()
        $ParserParams.LastUpdated = $LastUpdated
       
        # Create New Yaml File.
        $Parser = New-ParserTemplate @ParserParams
        $ParserYaml = ($Parser | ConvertTo-Yaml).TrimEnd()
        
        $ParserYaml | Out-File -FilePath $OutputPath -Force

    }
    else{
        Write-Host "No differences found"
    }
}
else {
    # No Existing File. Create a New File
    Write-Host "No Parser Found. Creating New Parser"
    $ParserParams = @{
        Title = $ParserTitle
        ParserAlias = $ParserAlias
        Version = $Version.ToString()
        LastUpdated = get-date -Format 'MMM dd yyy'
        ProductName = $ProductName
        Description = $Description
        ParserQuery = $ParserQuery   
    }
    
    $Parser = New-ParserTemplate @ParserParams
    
    ($Parser | ConvertTo-Yaml).TrimEnd() | Out-File -FilePath $OutputPath  -Force
}

Write-Host "Script Complete"