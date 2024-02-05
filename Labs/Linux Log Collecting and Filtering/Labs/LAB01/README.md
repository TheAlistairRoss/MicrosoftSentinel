# Lab 01

I haven't got this far yet!!! You will need this later

CommonSecurityLog Custom Table Deployment
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FTheAlistairRoss%2FMicrosoftSentinel%2Fmain%2FLabs%2FLinux%2520Log%2520Collecting%2520and%2520Filtering%2FBuild%2FCustomTables%2FCommonSecurityLog_CL.json)



## Useful Queries

```kusto
//Analytics Table KQL Transformation
source | project-away SourceIP, SourcePort

```
```kusto
//Basic Table KQL Transformation

source | project TimeGenerated, Computer, DeviceEventClassID, SourceIP, SourcePort

```

```kusto
// Review the Splitting
CommonSecurityLog
| project TimeGenerated, SourceIP
| extend Test = iff(isempty(SourceIP), "NoSourceIP","SourceIP")
| summarize count() by bin(TimeGenerated, 1m), Test
| render timechart
```

```kusto
// Get a Split Event
CommonSecurityLog
| where isempty(SourceIP)
| take 1
```

```kusto
// Basic Logs Query - Run it as a search job
CommonSecurityLog_CL
| where TimeGenerated == todatetime()
| where Computer == ""
| where DeviceEventClassID == ""
```


```kusto
// Join it all together
CommonSecurityLog_CL
| where TimeGenerated == todatetime()
| where Computer == ""
| where DeviceEventClassID == ""
| join (
    Incident1234_SRCH
)
on $left.TimeGenerated == $right._OriginalTimeGenerated, Computer, DeviceClassEventID

