param sentinelWorkspaceName string = 'sentinel'

param labName string = 'analyst-workshop'

param location string = resourceGroup().location

param numberOfAnalyticRules int = 15

@description('The Object Id of the Microsoft Entra security group which the users will be added to')
param userGroupId string 

@description('The Object Id of the Microsoft Entra App Registration')
param applicationObjectId string

var dataCollectionEndpointName = '${sentinelWorkspaceName}-${labName}-dce'
var dataCollectionRuleName = '${sentinelWorkspaceName}-${labName}-dcr'

var signInLogsTableName = 'SigninLogs_CL'
var signInLogsFunctionAlias = 'fSigninLogs'
var CustomSigninLogsSchema = [
  {
    name: 'TimeGenerated'
    type: 'datetime'
  }
  {
    name: 'OperationName'
    type: 'string'
  }
  {
    name: 'Category'
    type: 'string'
  }
  {
    name: 'ResultType'
    type: 'string'
  }
  {
    name: 'ResultDescription'
    type: 'string'
  }
  {
    name: 'CorrelationId'
    type: 'string'
  }
  {
    name: 'Identity'
    type: 'string'
  }
  {
    name: 'Level'
    type: 'string'
  }
  {
    name: 'Location'
    type: 'string'
  }
  {
    name: 'AppDisplayName'
    type: 'string'
  }
  {
    name: 'AppId'
    type: 'string'
  }
  {
    name: 'ClientAppUsed'
    type: 'string'
  }
  {
    name: 'ConditionalAccessStatus'
    type: 'string'
  }
  {
    name: 'DeviceDetail'
    type: 'dynamic'
  }
  {
    name: 'IPAddress'
    type: 'string'
  }
  {
    name: 'LocationDetails'
    type: 'dynamic'
  }
  {
    name: 'ResourceDisplayName'
    type: 'string'
  }
  {
    name: 'Status'
    type: 'dynamic'
  }
  {
    name: 'UserDisplayName'
    type: 'string'
  }
  {
    name: 'UserPrincipalName'
    type: 'string'
  }
  {
    name: 'UserType'
    type: 'string'
  }
]

var azureAdSigninLogsWorkbookDisplayName = 'Demo Azure AD Sign-in logs'
var azureAdSigninLogsWorkbookName = guid(resourceGroup().name, sentinelWorkspaceName, azureAdSigninLogsWorkbookDisplayName)

var contosoBreakGlassAlertName = 'Demo: Contoso Break Glass Account Login'
var contosoBreakGlassAlertId = guid(sentinelWorkspaceName, contosoBreakGlassAlertName)

var AutomationRuleName = 'Demo: Add Tasks To Contoso Break Glass Incident'

var MicrosoftSentinelConnectionName = 'Demo-Disable_User_Account-Connection'
var playbookDemoDisableUserAccountName = 'Demo-Disable_User_Account'

var monitoringMetricsPublisherRoleId = '3913510d-42f4-4e42-8a64-420c390055eb'
var microsoftSentinelAutomationContributorRoleId = 'f4c81013-99ee-4d62-a7ee-b3f1f648599a'
var microsoftSentinelContributorRoleId = 'ab8e14d6-4a74-4a29-9ba8-549422addade'
var microsoftSentinelResponderRoleId = '3e150937-b8fe-4cfb-8069-0eaf05ecd056'
var microsoftLogicAppContributorRoleId = '87a39d53-fc1b-424a-814c-f7e04687dc9e' 

var azureSecurityInsightsObjectId = '0afe49b8-0930-494a-a17e-2ac3402ec098'


resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: sentinelWorkspaceName
  location: location
}

resource sentinel 'Microsoft.SecurityInsights/onboardingStates@2023-02-01-preview' = {
  name: 'default'
  scope: logAnalyticsWorkspace
  properties: {}
}

resource customSigninLogsTable 'Microsoft.OperationalInsights/workspaces/tables@2022-10-01' = {
  parent: logAnalyticsWorkspace
  name: signInLogsTableName
  properties: {
    schema: {
      name: signInLogsTableName
      columns: CustomSigninLogsSchema
    }
  }
}

resource customSigninLogsFunction 'Microsoft.OperationalInsights/workspaces/savedSearches@2020-08-01' = {
  parent: logAnalyticsWorkspace
  name: toLower(signInLogsFunctionAlias)
  properties: {
    etag: '*'
    category: 'Demo'
    displayName: signInLogsFunctionAlias
    query: 'union isfuzzy=true SigninLogs, SigninLogs_CL'
    functionAlias: signInLogsFunctionAlias
  }
}

resource dataCollectionEndpoint 'Microsoft.Insights/dataCollectionEndpoints@2021-09-01-preview' = {
  name: dataCollectionEndpointName
  location: location
  properties: {
    networkAcls: {
      publicNetworkAccess: 'Enabled'
    }
  }
}

resource dataCollectionRule 'Microsoft.Insights/dataCollectionRules@2021-09-01-preview' = {
  name: dataCollectionRuleName
  location: location
  properties: {
    dataCollectionEndpointId: dataCollectionEndpoint.id
    dataFlows: [
      {
        streams: [
          'Custom-${customSigninLogsTable.name}'
        ]
        destinations: [
          'workspaceStream'
        ]
        transformKql: 'source'
        outputStream: 'Custom-${customSigninLogsTable.name}'
      }
    ]
    description: 'string'
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: logAnalyticsWorkspace.id
          name: 'workspaceStream'
        }
      ]
    }

    streamDeclarations: {
      'Custom-${customSigninLogsTable.name}': {
        columns: CustomSigninLogsSchema
      }
    }
  }
}

resource azureAdSigninWorkbook 'microsoft.insights/workbooks@2022-04-01' = {
  name: azureAdSigninLogsWorkbookName
  location: location
  kind: 'shared'
  properties: {
    displayName: azureAdSigninLogsWorkbookDisplayName
    serializedData: '{"version":"Notebook/1.0","items":[{"type":1,"content":{"json":"## Sign-in Analysis"},"name":"text - 0"},{"type":9,"content":{"version":"KqlParameterItem/1.0","parameters":[{"id":"13f56671-7604-4427-a4d8-663f3da0cbc5","version":"KqlParameterItem/1.0","name":"TimeRange","type":4,"isRequired":true,"value":{"durationMs":604800000},"typeSettings":{"selectableValues":[{"durationMs":300000,"isInitialTime":false,"grain":1,"useDashboardTimeRange":false},{"durationMs":900000,"isInitialTime":false,"grain":1,"useDashboardTimeRange":false},{"durationMs":1800000,"isInitialTime":false,"grain":1,"useDashboardTimeRange":false},{"durationMs":3600000,"isInitialTime":false,"grain":1,"useDashboardTimeRange":false},{"durationMs":14400000,"isInitialTime":false,"grain":1,"useDashboardTimeRange":false},{"durationMs":43200000,"isInitialTime":false,"grain":1,"useDashboardTimeRange":false},{"durationMs":86400000,"isInitialTime":false,"grain":1,"useDashboardTimeRange":false},{"durationMs":172800000,"isInitialTime":false,"grain":1,"useDashboardTimeRange":false},{"durationMs":259200000,"isInitialTime":false,"grain":1,"useDashboardTimeRange":false},{"durationMs":604800000,"isInitialTime":false,"grain":1,"useDashboardTimeRange":false},{"durationMs":1209600000,"isInitialTime":false,"grain":1,"useDashboardTimeRange":false},{"durationMs":2592000000,"isInitialTime":false,"grain":1,"useDashboardTimeRange":false}],"allowCustom":true}},{"id":"3b5cc420-8ad8-4523-ba28-a54910756794","version":"KqlParameterItem/1.0","name":"Apps","type":2,"isRequired":true,"multiSelect":true,"quote":"\'","delimiter":",","query":"fSigninLogs\\r\\n| summarize Count = count() by AppDisplayName\\r\\n| order by Count desc, AppDisplayName asc\\r\\n| project Value = AppDisplayName, Label = strcat(AppDisplayName, \' - \', Count, \' sign-ins\'), Selected = false\\r\\n","typeSettings":{"limitSelectTo":10,"additionalResourceOptions":["value::all"],"selectAllValue":"*","showDefault":false},"timeContext":{"durationMs":1209600000},"timeContextFromParameter":"TimeRange","defaultValue":"value::all","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces"},{"id":"0611ecce-d6a0-4a6f-a1bc-6be314ae36a7","version":"KqlParameterItem/1.0","name":"UserNamePrefix","type":2,"isRequired":true,"multiSelect":true,"quote":"\'","delimiter":",","query":"fSigninLogs\\r\\n|where AppDisplayName in ({Apps}) or \'*\' in ({Apps})\\r\\n| summarize Count = count() by UserDisplayName\\r\\n| order by Count desc, UserDisplayName asc\\r\\n| project Value = UserDisplayName, Label = strcat(UserDisplayName, \' - \', Count, \' sign-ins\'), Selected = false\\r\\n| extend prefix = substring(Value, 0, 1)\\r\\n| distinct prefix\\r\\n| sort by prefix asc","typeSettings":{"additionalResourceOptions":["value::all"],"selectAllValue":"*","showDefault":false},"timeContext":{"durationMs":1209600000},"timeContextFromParameter":"TimeRange","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces","value":["value::all"]},{"id":"f7f7970b-58c1-474f-9043-62243d2d4edd","version":"KqlParameterItem/1.0","name":"Users","label":"UserName","type":2,"isRequired":true,"multiSelect":true,"quote":"\'","delimiter":",","query":"fSigninLogs\\r\\n|where AppDisplayName in ({Apps}) or \'*\' in ({Apps})\\r\\n| summarize Count = count() by UserDisplayName\\r\\n| order by Count desc, UserDisplayName asc\\r\\n| project Value = UserDisplayName, Label = strcat(UserDisplayName, \' - \', Count, \' sign-ins\'), Selected = false\\r\\n| where (substring(Value, 0, 1) in ({UserNamePrefix})) or (\'*\' in ({UserNamePrefix}))\\r\\n| sort by Value asc\\r\\n","typeSettings":{"limitSelectTo":10000000,"additionalResourceOptions":["value::all"],"selectAllValue":"","showDefault":false},"timeContext":{"durationMs":1209600000},"timeContextFromParameter":"TimeRange","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces","value":["value::all"]},{"id":"85568f4e-9ad4-46c5-91d4-0ee1b2c8f3aa","version":"KqlParameterItem/1.0","name":"Category","type":2,"isRequired":true,"multiSelect":true,"quote":"\'","delimiter":",","typeSettings":{"additionalResourceOptions":["value::all"],"selectAllValue":"","showDefault":false},"jsonData":"[\\"SignInLogs\\", \\"NonInteractiveUserSignInLogs\\"]","value":["value::all"]}],"style":"pills","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces"},"name":"parameters - 1"},{"type":3,"content":{"version":"KqlItem/1.0","query":"let data = \\r\\nunion fSigninLogs,AADNonInteractiveUserSignInLogs\\r\\n| where Category in ({Category})\\r\\n|where AppDisplayName in ({Apps}) or \'*\' in ({Apps})\\r\\n|where UserDisplayName in ({Users});\\r\\ndata\\r\\n| summarize count() by UserPrincipalName, bin (TimeGenerated,5m)\\r\\n","size":0,"title":"Sign-in Trend over Time","timeContextFromParameter":"TimeRange","timeBrushParameterName":"TimeBrush","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces","visualization":"timechart"},"name":"query - 19"},{"type":3,"content":{"version":"KqlItem/1.0","query":"let nonInteractive = AADNonInteractiveUserSignInLogs\\r\\n| extend LocationDetails = parse_json(LocationDetails)\\r\\n| extend Status = parse_json(Status);\\r\\nlet data = \\r\\nunion fSigninLogs,nonInteractive\\r\\n| where Category in ({Category})\\r\\n|where AppDisplayName in ({Apps}) or \'*\' in ({Apps})\\r\\n|where UserDisplayName in ({Users}) \\r\\n|extend errorCode = ResultType\\r\\n|extend SigninStatus = case(errorCode == 0, \\"Success\\", errorCode == 50058, \\"Pending user action\\",errorCode == 50140, \\"Pending user action\\", errorCode == 51006, \\"Pending user action\\", errorCode == 50059, \\"Pending user action\\",errorCode == 65001, \\"Pending user action\\", errorCode == 52004, \\"Pending user action\\", errorCode == 50055, \\"Pending user action\\", errorCode == 50144, \\"Pending user action\\", errorCode == 50072, \\"Pending user action\\", errorCode == 50074, \\"Pending user action\\", errorCode == 16000, \\"Pending user action\\", errorCode == 16001, \\"Pending user action\\", errorCode == 16003, \\"Pending user action\\", errorCode == 50127, \\"Pending user action\\", errorCode == 50125, \\"Pending user action\\", errorCode == 50129, \\"Pending user action\\", errorCode == 50143, \\"Pending user action\\", errorCode == 81010, \\"Pending user action\\", errorCode == 81014, \\"Pending user action\\", errorCode == 81012 ,\\"Pending user action\\", \\"Failure\\");\\r\\ndata\\r\\n| summarize Count = count() by SigninStatus\\r\\n| join kind = fullouter (datatable(SigninStatus:string)[\'Success\', \'Pending action (Interrupts)\', \'Failure\']) on SigninStatus\\r\\n| project SigninStatus = iff(SigninStatus == \'\', SigninStatus1, SigninStatus), Count = iff(SigninStatus == \'\', 0, Count)\\r\\n| join kind = inner (data\\r\\n    | make-series Trend = count() default = 0 on TimeGenerated from {TimeRange:start} to {TimeRange:end} step {TimeRange:grain} by SigninStatus)\\r\\n    on SigninStatus\\r\\n| project-away SigninStatus1, TimeGenerated\\r\\n| extend Status = SigninStatus\\r\\n| union (\\r\\n    data \\r\\n    | summarize Count = count()\\r\\n    | extend jkey = 1\\r\\n    | join kind=inner (data\\r\\n        | make-series Trend = count() default = 0 on TimeGenerated from {TimeRange:start} to {TimeRange:end} step {TimeRange:grain}\\r\\n        | extend jkey = 1) on jkey\\r\\n    | extend SigninStatus = \'All Sign-ins\', Status = \'*\'    \\r\\n)\\r\\n| order by Count desc\\r\\n\\r\\n\\r\\n\\r\\n","size":3,"timeContextFromParameter":"TimeBrush","exportFieldName":"Status","exportParameterName":"SigninStatus","exportDefaultValue":"*","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces","visualization":"tiles","tileSettings":{"titleContent":{"columnMatch":"SigninStatus","formatter":1,"formatOptions":{"showIcon":true}},"leftContent":{"columnMatch":"Count","formatter":12,"formatOptions":{"palette":"blue","showIcon":true},"numberFormat":{"unit":17,"options":{"style":"decimal","maximumFractionDigits":2,"maximumSignificantDigits":3}}},"secondaryContent":{"columnMatch":"Trend","formatter":9,"formatOptions":{"min":0,"palette":"blue","showIcon":true}},"showBorder":false}},"name":"query - 5"},{"type":1,"content":{"json":"<br />\\r\\n💡 _Click on a tile or a row in the grid to drill-in further_"},"name":"text - 6 - Copy"},{"type":3,"content":{"version":"KqlItem/1.0","query":"let nonInteractive = AADNonInteractiveUserSignInLogs\\r\\n| extend LocationDetails = parse_json(LocationDetails)\\r\\n| extend Status = parse_json(Status);\\r\\nlet data = \\r\\nunion fSigninLogs,nonInteractive\\r\\n| extend AppDisplayName = iff(AppDisplayName == \'\', \'Unknown\', AppDisplayName)\\r\\n|where AppDisplayName in ({Apps}) or \'*\' in ({Apps})\\r\\n|where UserDisplayName in ({Users}) \\r\\n| extend Country = iff(LocationDetails.countryOrRegion == \'\', \'Unknown country\', tostring(LocationDetails.countryOrRegion))\\r\\n| extend City = iff(LocationDetails.city == \'\', \'Unknown city\', tostring(LocationDetails.city))\\r\\n| extend errorCode = ResultType\\r\\n| extend SigninStatus = case(errorCode == 0, \\"Success\\", errorCode == 50058, \\"Pending user action\\",errorCode == 50140, \\"Pending user action\\", errorCode == 51006, \\"Pending user action\\", errorCode == 50059, \\"Pending user action\\",errorCode == 65001, \\"Pending user action\\", errorCode == 52004, \\"Pending user action\\", errorCode == 50055, \\"Pending user action\\", errorCode == 50144, \\"Pending user action\\", errorCode == 50072, \\"Pending user action\\", errorCode == 50074, \\"Pending user action\\", errorCode == 16000, \\"Pending user action\\", errorCode == 16001, \\"Pending user action\\", errorCode == 16003, \\"Pending user action\\", errorCode == 50127, \\"Pending user action\\", errorCode == 50125, \\"Pending user action\\", errorCode == 50129, \\"Pending user action\\", errorCode == 50143, \\"Pending user action\\", errorCode == 81010, \\"Pending user action\\", errorCode == 81014, \\"Pending user action\\", errorCode == 81012 ,\\"Pending user action\\", \\"Failure\\")\\r\\n| where SigninStatus == \'{SigninStatus}\' or \'{SigninStatus}\' == \'*\' or \'{SigninStatus}\' == \'All Sign-ins\';\\r\\nlet countryData = data\\r\\n| summarize TotalCount = count(), SuccessCount = countif(SigninStatus == \\"Success\\"), FailureCount = countif(SigninStatus == \\"Failure\\"), InterruptCount = countif(SigninStatus == \\"Pending user action\\") by Country,Category\\r\\n| join kind=inner\\r\\n(\\r\\n    data\\r\\n| make-series Trend = count() default = 0 on TimeGenerated in range({TimeRange:start}, {TimeRange:end}, {TimeRange:grain}) by  Country\\r\\n| project-away TimeGenerated\\r\\n)\\r\\non Country\\r\\n| project Country, TotalCount, SuccessCount,FailureCount,InterruptCount,Trend,Category\\r\\n| order by TotalCount desc, Country asc;\\r\\ndata\\r\\n| summarize TotalCount = count(), SuccessCount = countif(SigninStatus == \\"Success\\"), FailureCount = countif(SigninStatus == \\"Failure\\"), InterruptCount = countif(SigninStatus == \\"Pending user action\\") by Country, City,Category\\r\\n| join kind=inner\\r\\n(\\r\\n    data    \\r\\n| make-series Trend = count() default = 0 on TimeGenerated in range({TimeRange:start}, {TimeRange:end}, {TimeRange:grain}) by Country, City\\r\\n| project-away TimeGenerated\\r\\n)\\r\\non Country, City\\r\\n| order by TotalCount desc, Country asc\\r\\n| project Country, City,TotalCount, SuccessCount,FailureCount,InterruptCount, Trend,Category\\r\\n| join kind=inner\\r\\n(\\r\\n    countryData\\r\\n)\\r\\non Country\\r\\n| project Id = City, Name = City, Type = \'City\', [\'Sign-in Count\'] = TotalCount, Trend, [\'Failure Count\'] = FailureCount, [\'Interrupt Count\'] = InterruptCount, [\'Success Rate\'] = 1.0 * SuccessCount / TotalCount, ParentId = Country,Category\\r\\n| union (countryData\\r\\n| project Id = Country, Name = Country, Type = \'Country\', [\'Sign-in Count\'] = TotalCount, Trend, [\'Failure Count\'] = FailureCount, [\'Interrupt Count\'] = InterruptCount, [\'Success Rate\'] = 1.0 * SuccessCount / TotalCount, ParentId = \'root\',Category)\\r\\n| where Category in ({Category})\\r\\n| order by [\'Sign-in Count\'] desc, Name asc\\r\\n","size":1,"showAnalytics":true,"title":"Sign-ins by Location","timeContextFromParameter":"TimeBrush","showRefreshButton":true,"exportMultipleValues":true,"exportedParameters":[{"fieldName":"Name","parameterName":"LocationDetail","parameterType":1}],"queryType":0,"resourceType":"microsoft.operationalinsights/workspaces","visualization":"table","gridSettings":{"formatters":[{"columnMatch":"Id","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Type","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Sign-in Count","formatter":8,"formatOptions":{"min":0,"palette":"blue","showIcon":true},"numberFormat":{"unit":17,"options":{"style":"decimal"}}},{"columnMatch":"Trend","formatter":9,"formatOptions":{"min":0,"palette":"blue","showIcon":true}},{"columnMatch":"Failure Count|Interrupt Count","formatter":8,"formatOptions":{"min":0,"palette":"orange","showIcon":true},"numberFormat":{"unit":17,"options":{"style":"decimal"}}},{"columnMatch":"Success Rate","formatter":5,"formatOptions":{"showIcon":true},"numberFormat":{"unit":0,"options":{"style":"percent"}}},{"columnMatch":"ParentId","formatter":5,"formatOptions":{"showIcon":true}}],"filter":true,"hierarchySettings":{"idColumn":"Id","parentColumn":"ParentId","treeType":0,"expanderColumn":"Name","expandTopLevel":false}}},"customWidth":"67","showPin":true,"name":"query - 8"},{"type":3,"content":{"version":"KqlItem/1.0","query":"let selectedCountry = dynamic([{LocationDetail}]);\\r\\nlet nonInteractive = AADNonInteractiveUserSignInLogs\\r\\n| extend LocationDetails = parse_json(LocationDetails),Status = parse_json(Status),ConditionalAccessPolicies = parse_json(ConditionalAccessPolicies),DeviceDetail =parse_json(DeviceDetail);\\r\\nlet details = dynamic({ \\"Name\\":\\"\\", \\"Type\\":\\"*\\"});\\r\\nlet data = union fSigninLogs,nonInteractive\\r\\n| extend AppDisplayName = iff(AppDisplayName == \'\', \'Unknown\', AppDisplayName)\\r\\n|where AppDisplayName in ({Apps}) or \'*\' in ({Apps})\\r\\n|where UserDisplayName in ({Users}) \\r\\n| extend Country = tostring(LocationDetails.countryOrRegion)\\r\\n| where array_length(selectedCountry) == 0 or \\"*\\" in (selectedCountry) or Country in (selectedCountry)\\r\\n| extend City = tostring(LocationDetails.city)\\r\\n| extend errorCode = ResultType\\r\\n| extend SigninStatus = case(errorCode == 0, \\"Success\\", errorCode == 50058, \\"Pending user action\\",errorCode == 50140, \\"Pending user action\\", errorCode == 51006, \\"Pending user action\\", errorCode == 50059, \\"Pending user action\\",errorCode == 65001, \\"Pending user action\\", errorCode == 52004, \\"Pending user action\\", errorCode == 50055, \\"Pending user action\\", errorCode == 50144, \\"Pending user action\\", errorCode == 50072, \\"Pending user action\\", errorCode == 50074, \\"Pending user action\\", errorCode == 16000, \\"Pending user action\\", errorCode == 16001, \\"Pending user action\\", errorCode == 16003, \\"Pending user action\\", errorCode == 50127, \\"Pending user action\\", errorCode == 50125, \\"Pending user action\\", errorCode == 50129, \\"Pending user action\\", errorCode == 50143, \\"Pending user action\\", errorCode == 81010, \\"Pending user action\\", errorCode == 81014, \\"Pending user action\\", errorCode == 81012 ,\\"Pending user action\\", \\"Failure\\")\\r\\n| where SigninStatus == \'{SigninStatus}\' or \'{SigninStatus}\' == \'*\' or \'{SigninStatus}\' == \'All Sign-ins\'\\r\\n| where details.Type == \'*\' or (details.Type == \'Country\' and Country == details.Name) or (details.Type == \'City\' and City == details.Name);\\r\\ndata\\r\\n| top 200 by TimeGenerated desc\\r\\n| extend TimeFromNow = now() - TimeGenerated\\r\\n| extend TimeAgo = strcat(case(TimeFromNow < 2m, strcat(toint(TimeFromNow / 1m), \' seconds\'), TimeFromNow < 2h, strcat(toint(TimeFromNow / 1m), \' minutes\'), TimeFromNow < 2d, strcat(toint(TimeFromNow / 1h), \' hours\'), strcat(toint(TimeFromNow / 1d), \' days\')), \' ago\')\\r\\n| project User = UserDisplayName, [\'Sign-in Status\'] = strcat(iff(SigninStatus == \'Success\', \'✔️\', \'❌\'), \' \', SigninStatus), [\'Sign-in Time\'] = TimeAgo, App = AppDisplayName, [\'Error code\'] = errorCode, [\'Result type\'] = ResultType, [\'Result signature\'] = ResultSignature, [\'Result description\'] = ResultDescription, [\'Conditional access policies\'] = ConditionalAccessPolicies, [\'Conditional access status\'] = ConditionalAccessStatus, [\'Operating system\'] = DeviceDetail.operatingSystem, Browser = DeviceDetail.browser, [\'Country or region\'] = LocationDetails.countryOrRegion, [\'State\'] = LocationDetails.state, [\'City\'] = LocationDetails.city, [\'Time generated\'] = TimeGenerated, Status, [\'User principal name\'] = UserPrincipalName, Category\\r\\n| where Category in ({Category})\\r\\n\\r\\n\\r\\n","size":1,"showAnalytics":true,"title":"Location Sign-in details","timeContextFromParameter":"TimeBrush","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces","gridSettings":{"formatters":[{"columnMatch":"Sign-in Status","formatter":7,"formatOptions":{"linkTarget":"CellDetails","showIcon":true}},{"columnMatch":"App","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Error code","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Result type","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Result signature","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Result description","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Conditional access policies","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Conditional access status","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Operating system","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Browser","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Country or region","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"State","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"City","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Time generated","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Status","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"User principal name","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"TimeGenerated","formatter":5,"formatOptions":{"showIcon":true}}],"filter":true}},"customWidth":"33","name":"query - 8"},{"type":3,"content":{"version":"KqlItem/1.0","query":"let nonInteractive = AADNonInteractiveUserSignInLogs | extend LocationDetails = parse_json(LocationDetails), Status = parse_json(Status), DeviceDetail = parse_json(DeviceDetail);\\r\\nlet data = \\r\\nunion fSigninLogs,nonInteractive\\r\\n|where AppDisplayName in ({Apps}) or \'*\' in ({Apps})\\r\\n|where UserDisplayName in ({Users}) \\r\\n    | extend errorCode = ResultType\\r\\n    | extend SigninStatus = case(errorCode == 0, \\"Success\\", errorCode == 50058, \\"Pending user action\\", errorCode == 50140, \\"Pending user action\\", errorCode == 51006, \\"Pending user action\\", errorCode == 50059, \\"Pending user action\\", errorCode == 65001, \\"Pending user action\\", errorCode == 52004, \\"Pending user action\\", errorCode == 50055, \\"Pending user action\\", errorCode == 50144, \\"Pending user action\\", errorCode == 50072, \\"Pending user action\\", errorCode == 50074, \\"Pending user action\\", errorCode == 16000, \\"Pending user action\\", errorCode == 16001, \\"Pending user action\\", errorCode == 16003, \\"Pending user action\\", errorCode == 50127, \\"Pending user action\\", errorCode == 50125, \\"Pending user action\\", errorCode == 50129, \\"Pending user action\\", errorCode == 50143, \\"Pending user action\\", errorCode == 81010, \\"Pending user action\\", errorCode == 81014, \\"Pending user action\\", errorCode == 81012, \\"Pending user action\\", \\"Failure\\")\\r\\n| where SigninStatus == \'{SigninStatus}\' or \'{SigninStatus}\' == \'*\' or \'{SigninStatus}\' == \'All Sign-ins\';\\r\\nlet appData = data\\r\\n    | summarize TotalCount = count(), SuccessCount = countif(SigninStatus == \\"Success\\"), FailureCount = countif(SigninStatus == \\"Failure\\"), InterruptCount = countif(SigninStatus == \\"Pending user action\\") by Os = tostring(DeviceDetail.operatingSystem) ,Category\\r\\n    | where Os != \'\'\\r\\n    | join kind=inner (data\\r\\n        | make-series Trend = count() default = 0 on TimeGenerated in range({TimeRange:start}, {TimeRange:end}, {TimeRange:grain}) by Os = tostring(DeviceDetail.operatingSystem)\\r\\n        | project-away TimeGenerated)\\r\\n        on Os\\r\\n    | order by TotalCount desc, Os asc\\r\\n    | project Os, TotalCount, SuccessCount, FailureCount, InterruptCount, Trend,Category\\r\\n    | serialize Id = row_number();\\r\\ndata\\r\\n| summarize TotalCount = count(), SuccessCount = countif(SigninStatus == \\"Success\\"), FailureCount = countif(SigninStatus == \\"Failure\\"), InterruptCount = countif(SigninStatus == \\"Pending user action\\") by Os = tostring(DeviceDetail.operatingSystem), Browser = tostring(DeviceDetail.browser),Category\\r\\n| join kind=inner (data\\r\\n    | make-series Trend = count() default = 0 on TimeGenerated in range({TimeRange:start}, {TimeRange:end}, {TimeRange:grain})by Os = tostring(DeviceDetail.operatingSystem), Browser = tostring(DeviceDetail.browser)\\r\\n    | project-away TimeGenerated)\\r\\n    on Os, Browser\\r\\n| order by TotalCount desc, Os asc\\r\\n| project Os, Browser, TotalCount, SuccessCount, FailureCount, InterruptCount, Trend,Category\\r\\n| serialize Id = row_number(1000000)\\r\\n| join kind=inner (appData) on Os\\r\\n| project Id, Name = Browser, Type = \'Browser\', [\'Sign-in Count\'] = TotalCount, Trend, [\'Failure Count\'] = FailureCount, [\'Interrupt Count\'] = InterruptCount, [\'Success Rate\'] = 1.0 * SuccessCount / TotalCount, ParentId = Id1,Category\\r\\n| union (appData \\r\\n    | project Id, Name = Os, Type = \'Operating System\', [\'Sign-in Count\'] = TotalCount, Trend, [\'Failure Count\'] = FailureCount, [\'Interrupt Count\'] = InterruptCount, [\'Success Rate\'] = 1.0 * SuccessCount / TotalCount, ParentId = -1,Category)\\r\\n| where Category in ({Category})\\r\\n| order by [\'Sign-in Count\'] desc, Name asc\\r\\n","size":1,"showAnalytics":true,"title":"Sign-ins by Device","timeContextFromParameter":"TimeBrush","exportedParameters":[{"parameterName":"DeviceDetail","defaultValue":"{ \\"Name\\":\\"\\", \\"Type\\":\\"*\\"}"},{"fieldName":"Category","parameterName":"exportCategory","parameterType":1,"defaultValue":"*"},{"fieldName":"Name","parameterName":"exportName","parameterType":1,"defaultValue":"*"}],"queryType":0,"resourceType":"microsoft.operationalinsights/workspaces","visualization":"table","gridSettings":{"formatters":[{"columnMatch":"Id","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Type","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Sign-in Count","formatter":8,"formatOptions":{"min":0,"palette":"blue","showIcon":true},"numberFormat":{"unit":17,"options":{"style":"decimal"}}},{"columnMatch":"Trend","formatter":9,"formatOptions":{"min":0,"palette":"blue","showIcon":true},"numberFormat":{"unit":17,"options":{"style":"decimal"}}},{"columnMatch":"Failure Count|Interrupt Count","formatter":8,"formatOptions":{"min":0,"palette":"orange","showIcon":true},"numberFormat":{"unit":17,"options":{"style":"decimal"}}},{"columnMatch":"Success Rate","formatter":5,"formatOptions":{"showIcon":true},"numberFormat":{"unit":0,"options":{"style":"percent"}}},{"columnMatch":"ParentId","formatter":5,"formatOptions":{"showIcon":true}}],"filter":true,"hierarchySettings":{"idColumn":"Id","parentColumn":"ParentId","treeType":0,"expanderColumn":"Name","expandTopLevel":false}}},"customWidth":"67","showPin":true,"name":"query - 9"},{"type":3,"content":{"version":"KqlItem/1.0","query":"let nonInteractive = AADNonInteractiveUserSignInLogs\\r\\n| extend LocationDetails = parse_json(LocationDetails),Status = parse_json(Status),ConditionalAccessPolicies = parse_json(ConditionalAccessPolicies),DeviceDetail =parse_json(DeviceDetail);\\r\\nlet details = dynamic({ \\"Name\\":\\"\\", \\"Type\\":\\"*\\"});\\r\\nlet data = union fSigninLogs,nonInteractive\\r\\n| extend AppDisplayName = iff(AppDisplayName == \'\', \'Unknown\', AppDisplayName)\\r\\n|where AppDisplayName in ({Apps}) or \'*\' in ({Apps})\\r\\n|where UserDisplayName in ({Users}) \\r\\n| extend Country = tostring(LocationDetails.countryOrRegion)\\r\\n| extend City = tostring(LocationDetails.city)\\r\\n| extend errorCode = ResultType\\r\\n| extend SigninStatus = case(errorCode == 0, \\"Success\\", errorCode == 50058, \\"Pending user action\\",errorCode == 50140, \\"Pending user action\\", errorCode == 51006, \\"Pending user action\\", errorCode == 50059, \\"Pending user action\\",errorCode == 65001, \\"Pending user action\\", errorCode == 52004, \\"Pending user action\\", errorCode == 50055, \\"Pending user action\\", errorCode == 50144, \\"Pending user action\\", errorCode == 50072, \\"Pending user action\\", errorCode == 50074, \\"Pending user action\\", errorCode == 16000, \\"Pending user action\\", errorCode == 16001, \\"Pending user action\\", errorCode == 16003, \\"Pending user action\\", errorCode == 50127, \\"Pending user action\\", errorCode == 50125, \\"Pending user action\\", errorCode == 50129, \\"Pending user action\\", errorCode == 50143, \\"Pending user action\\", errorCode == 81010, \\"Pending user action\\", errorCode == 81014, \\"Pending user action\\", errorCode == 81012 ,\\"Pending user action\\", \\"Failure\\")\\r\\n| where SigninStatus == \'{SigninStatus}\' or \'{SigninStatus}\' == \'*\' or \'{SigninStatus}\' == \'All Sign-ins\'\\r\\n| where details.Type == \'*\' or (details.Type == \'Country\' and Country == details.Name) or (details.Type == \'City\' and City == details.Name);\\r\\ndata\\r\\n| top 200 by TimeGenerated desc\\r\\n| extend TimeFromNow = now() - TimeGenerated\\r\\n| extend TimeAgo = strcat(case(TimeFromNow < 2m, strcat(toint(TimeFromNow / 1m), \' seconds\'), TimeFromNow < 2h, strcat(toint(TimeFromNow / 1m), \' minutes\'), TimeFromNow < 2d, strcat(toint(TimeFromNow / 1h), \' hours\'), strcat(toint(TimeFromNow / 1d), \' days\')), \' ago\')\\r\\n| project User = UserDisplayName, [\'Sign-in Status\'] = strcat(iff(SigninStatus == \'Success\', \'✔️\', \'❌\'), \' \', SigninStatus), [\'Sign-in Time\'] = TimeAgo, App = AppDisplayName, [\'Error code\'] = errorCode, [\'Result type\'] = ResultType, [\'Result signature\'] = ResultSignature, [\'Result description\'] = ResultDescription, [\'Conditional access policies\'] = ConditionalAccessPolicies, [\'Conditional access status\'] = ConditionalAccessStatus, [\'Operating system\'] = DeviceDetail.operatingSystem, Browser = DeviceDetail.browser, [\'Country or region\'] = LocationDetails.countryOrRegion, [\'State\'] = LocationDetails.state, [\'City\'] = LocationDetails.city, [\'Time generated\'] = TimeGenerated, Status, [\'User principal name\'] = UserPrincipalName, Category, Name = tostring(DeviceDetail.operatingSystem)\\r\\n| where Category in (\'{exportCategory}\') or \\"*\\" in (\'{exportCategory}\')\\r\\n| where Name in (\'{exportName}\') or \\"*\\" in (\'{exportName}\')","size":1,"showAnalytics":true,"title":"Device Sign-in details","timeContextFromParameter":"TimeRange","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces","gridSettings":{"formatters":[{"columnMatch":"Sign-in Status","formatter":7,"formatOptions":{"linkTarget":"CellDetails"}},{"columnMatch":"App","formatter":5},{"columnMatch":"Error code","formatter":5},{"columnMatch":"Result type","formatter":5},{"columnMatch":"Result signature","formatter":5},{"columnMatch":"Result description","formatter":5},{"columnMatch":"Conditional access policies","formatter":5},{"columnMatch":"Conditional access status","formatter":5},{"columnMatch":"Operating system","formatter":5},{"columnMatch":"Browser","formatter":5},{"columnMatch":"Country or region","formatter":5},{"columnMatch":"State","formatter":5},{"columnMatch":"City","formatter":5},{"columnMatch":"Time generated","formatter":5},{"columnMatch":"Status","formatter":5},{"columnMatch":"User principal name","formatter":5},{"columnMatch":"Category","formatter":5},{"columnMatch":"Name","formatter":5}],"filter":true}},"customWidth":"33","name":"query - 8 - Copy"},{"type":1,"content":{"json":"## Sign-ins using Conditional Access"},"name":"text - 12"},{"type":3,"content":{"version":"KqlItem/1.0","query":"let nonInteractive = AADNonInteractiveUserSignInLogs\\r\\n| extend LocationDetails = parse_json(LocationDetails)\\r\\n| extend Status = parse_json(Status)\\r\\n| extend ConditionalAccessPolicies = parse_json(ConditionalAccessPolicies);\\r\\nlet data = \\r\\nunion fSigninLogs,nonInteractive\\r\\n|where AppDisplayName in ({Apps}) or \'*\' in ({Apps})\\r\\n|where UserDisplayName in ({Users}) \\r\\n|extend CAStatus = case(ConditionalAccessStatus ==\\"success\\",\\"Successful\\",\\r\\n                    ConditionalAccessStatus == \\"failure\\", \\"Failed\\",                                     \\r\\n                    ConditionalAccessStatus == \\"notApplied\\", \\"Not applied\\",                                     \\r\\n                    isempty(ConditionalAccessStatus), \\"Not applied\\", \\r\\n                    \\"Disabled\\")\\r\\n|mvexpand ConditionalAccessPolicies\\r\\n|extend CAGrantControlName = tostring(ConditionalAccessPolicies.enforcedGrantControls[0])\\r\\n|extend CAGrantControl = case(CAGrantControlName contains \\"MFA\\", \\"Require MFA\\", \\r\\n                            CAGrantControlName contains \\"Terms of Use\\", \\"Require Terms of Use\\", \\r\\n                            CAGrantControlName contains \\"Privacy\\", \\"Require Privacy Statement\\", \\r\\n                            CAGrantControlName contains \\"Device\\", \\"Require Device Compliant\\", \\r\\n                            CAGrantControlName contains \\"Azure AD Joined\\", \\"Require Hybird Azure AD Joined Device\\", \\r\\n                            CAGrantControlName contains \\"Apps\\", \\"Require Approved Apps\\",\\r\\n                            \\"Other\\");\\r\\ndata\\r\\n| where Category in ({Category})\\r\\n| summarize Count = dcount(Id) by CAStatus\\r\\n| join kind = inner (data\\r\\n                    | make-series Trend = dcount(Id) default = 0 on TimeGenerated in range({TimeRange:start}, {TimeRange:end}, {TimeRange:grain}) by CAStatus\\r\\n                    ) on CAStatus\\r\\n| project-away CAStatus1, TimeGenerated\\r\\n| order by Count desc","size":4,"title":"Conditional access status","timeContextFromParameter":"TimeBrush","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces","visualization":"tiles","tileSettings":{"titleContent":{"columnMatch":"CAStatus","formatter":1},"subtitleContent":{"columnMatch":"Category"},"leftContent":{"columnMatch":"Count","formatter":12,"formatOptions":{"palette":"auto"},"numberFormat":{"unit":17,"options":{"maximumSignificantDigits":3,"maximumFractionDigits":2}}},"showBorder":false}},"name":"query - 9"},{"type":3,"content":{"version":"KqlItem/1.0","query":"let nonInteractive = AADNonInteractiveUserSignInLogs\\r\\n| extend LocationDetails = parse_json(LocationDetails)\\r\\n| extend Status = parse_json(Status)\\r\\n| extend ConditionalAccessPolicies = parse_json(ConditionalAccessPolicies);\\r\\nlet data = \\r\\nunion fSigninLogs,nonInteractive|where AppDisplayName in ({Apps}) or \'*\' in ({Apps})\\r\\n|where UserDisplayName in ({Users}) \\r\\n|extend errorCode = toint(ResultType)\\r\\n|extend Reason = tostring(Status.failureReason)\\r\\n|extend CAStatus = case(ConditionalAccessStatus ==0,\\"✔️ Success\\",                                     \\r\\n                        ConditionalAccessStatus == 1, \\"❌ Failure\\",                                     \\r\\n                        ConditionalAccessStatus == 2, \\"⚠️ Not Applied\\",                                     \\r\\n                        ConditionalAccessStatus == \\"\\", \\"⚠️ Not Applied\\", \\r\\n                        \\"🚫 Disabled\\")\\r\\n|mvexpand ConditionalAccessPolicies\\r\\n|extend CAGrantControlName = tostring(ConditionalAccessPolicies.enforcedGrantControls[0])\\r\\n|extend CAGrantControl = case(CAGrantControlName contains \\"MFA\\", \\"Require MFA\\", \\r\\n                            CAGrantControlName contains \\"Terms of Use\\", \\"Require Terms of Use\\", \\r\\n                            CAGrantControlName contains \\"Privacy\\", \\"Require Privacy Statement\\", \\r\\n                            CAGrantControlName contains \\"Device\\", \\"Require Device Compliant\\", \\r\\n                            CAGrantControlName contains \\"Azure AD Joined\\", \\"Require Hybird Azure AD Joined Device\\", \\r\\n                            CAGrantControlName contains \\"Apps\\", \\"Require Approved Apps\\",\\"Other\\");\\r\\ndata\\r\\n| summarize Count = dcount(Id) by CAStatus, CAGrantControl\\r\\n| project Id = strcat(CAStatus, \'/\', CAGrantControl), Name = CAGrantControl, Parent = CAStatus, Count, Type = \'CAGrantControl\'\\r\\n| join kind = inner (data\\r\\n                    | make-series Trend = dcount(Id) default = 0 on TimeGenerated in range({TimeRange:start}, {TimeRange:end}, {TimeRange:grain}) by CAStatus, CAGrantControl\\r\\n                    | project Id = strcat(CAStatus, \'/\', CAGrantControl), Trend\\r\\n                    ) on Id\\r\\n| project-away Id1\\r\\n| union (data\\r\\n    | where Category in ({Category})\\r\\n    | summarize Count = dcount(Id) by CAStatus\\r\\n    | project Id = CAStatus, Name = CAStatus, Parent = \'\', Count, Type = \'CAStatus\'\\r\\n    | join kind = inner (data\\r\\n                        | make-series Trend = dcount(Id) default = 0 on TimeGenerated in range({TimeRange:start}, {TimeRange:end}, {TimeRange:grain}) by CAStatus\\r\\n                        | project Id = CAStatus, Trend\\r\\n                        ) on Id\\r\\n    | project-away Id1)\\r\\n| order by Count desc","size":0,"title":"Conditional access status","timeContextFromParameter":"TimeBrush","exportParameterName":"Detail","exportDefaultValue":"{ \\"Name\\":\\"\\", \\"Type\\":\\"*\\", \\"Parent\\":\\"*\\"}","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces","visualization":"table","gridSettings":{"formatters":[{"columnMatch":"Id","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Parent","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Count","formatter":8,"formatOptions":{"min":0,"palette":"blue","showIcon":true},"numberFormat":{"unit":0,"options":{"style":"decimal"}}},{"columnMatch":"Type","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Trend","formatter":9,"formatOptions":{"min":0,"palette":"blue","showIcon":true}}],"hierarchySettings":{"idColumn":"Id","parentColumn":"Parent","treeType":0,"expanderColumn":"Name","expandTopLevel":true}}},"customWidth":"50","name":"query - 10","styleSettings":{"margin":"50"}},{"type":3,"content":{"version":"KqlItem/1.0","query":"let details = dynamic({Detail});\\r\\nlet nonInteractive = AADNonInteractiveUserSignInLogs\\r\\n| extend LocationDetails = parse_json(LocationDetails)\\r\\n| extend Status = parse_json(Status)\\r\\n| extend ConditionalAccessPolicies = parse_json(ConditionalAccessPolicies);\\r\\nlet data = \\r\\nunion fSigninLogs,nonInteractive\\r\\n|where AppDisplayName in ({Apps}) or \'*\' in ({Apps})\\r\\n|where UserDisplayName in ({Users}) \\r\\n|extend errorCode = toint(ResultType)\\r\\n|extend Reason = tostring(Status.failureReason)\\r\\n|extend CAStatus = case(ConditionalAccessStatus ==\\"success\\",\\"✔️ Success\\",                                     \\r\\n                        ConditionalAccessStatus == \\"failure\\", \\"❌ Failure\\",                                     \\r\\n                        ConditionalAccessStatus == \\"notApplied\\", \\"⚠️ Not Applied\\",                                     \\r\\n                        ConditionalAccessStatus == \\"\\", \\"⚠️ Not Applied\\", \\r\\n                        \\"🚫 Disabled\\")\\r\\n|mvexpand ConditionalAccessPolicies\\r\\n|extend CAGrantControlName = tostring(ConditionalAccessPolicies.enforcedGrantControls[0])\\r\\n|extend CAGrantControl = case(CAGrantControlName contains \\"MFA\\", \\"Require MFA\\", \\r\\n                            CAGrantControlName contains \\"Terms of Use\\", \\"Require Terms of Use\\", \\r\\n                            CAGrantControlName contains \\"Privacy\\", \\"Require Privacy Statement\\", \\r\\n                            CAGrantControlName contains \\"Device\\", \\"Require Device Compliant\\", \\r\\n                            CAGrantControlName contains \\"Azure AD Joined\\", \\"Require Hybird Azure AD Joined Device\\", \\r\\n                            CAGrantControlName contains \\"Apps\\", \\"Require Approved Apps\\",\\r\\n                            \\"Other\\")\\r\\n|extend CAGrantControlRank = case(CAGrantControlName contains \\"MFA\\", 1, \\r\\n                            CAGrantControlName contains \\"Terms of Use\\", 2, \\r\\n                            CAGrantControlName contains \\"Privacy\\", 3, \\r\\n                            CAGrantControlName contains \\"Device\\", 4, \\r\\n                            CAGrantControlName contains \\"Azure AD Joined\\", 5, \\r\\n                            CAGrantControlName contains \\"Apps\\", 6,\\r\\n                            7)\\r\\n| where details.Type == \'*\' or (details.Type == \'CAStatus\' and CAStatus == details.Name) or (details.Type == \'CAGrantControl\' and CAGrantControl == details.Name and CAStatus == details.Parent);\\r\\ndata\\r\\n| order by CAGrantControlRank desc\\r\\n| summarize CAGrantControls = make_set(CAGrantControl) by AppDisplayName, CAStatus, TimeGenerated, UserDisplayName, Category\\r\\n| extend CAGrantControlText = replace(@\\",\\", \\", \\", replace(@\'\\"\', @\'\', replace(@\\"\\\\]\\", @\\"\\", replace(@\\"\\\\[\\", @\\"\\", tostring(CAGrantControls)))))\\r\\n| extend CAGrantControlSummary = case(array_length(CAGrantControls) > 1, strcat(CAGrantControls[0], \' + \', array_length(CAGrantControls) - 1, \' more\'), array_length(CAGrantControls) == 1, tostring(CAGrantControls[0]), \'None\')\\r\\n| top 200 by TimeGenerated desc\\r\\n| extend TimeFromNow = now() - TimeGenerated\\r\\n| extend TimeAgo = strcat(case(TimeFromNow < 2m, strcat(toint(TimeFromNow / 1m), \' seconds\'), TimeFromNow < 2h, strcat(toint(TimeFromNow / 1m), \' minutes\'), TimeFromNow < 2d, strcat(toint(TimeFromNow / 1h), \' hours\'), strcat(toint(TimeFromNow / 1d), \' days\')), \' ago\')\\r\\n| project Application = AppDisplayName, [\'CA Status\'] = CAStatus, [\'CA Grant Controls\'] = CAGrantControlSummary, [\'All CA Grant Controls\'] = CAGrantControlText, [\'Sign-in Time\'] = TimeAgo, [\'User\'] = UserDisplayName, Category\\r\\n| where Category in ({Category})","size":0,"showAnalytics":true,"title":"Recent sign-ins","timeContextFromParameter":"TimeRange","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces","visualization":"table","gridSettings":{"formatters":[{"columnMatch":"CA Grant Controls","formatter":1,"formatOptions":{"showIcon":true}},{"columnMatch":"All CA Grant Controls","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"User","formatter":5,"formatOptions":{"showIcon":true}}]}},"customWidth":"50","showPin":true,"name":"query - 7 - Copy"},{"type":1,"content":{"json":"## Troubleshooting Sign-ins"},"name":"text - 13"},{"type":3,"content":{"version":"KqlItem/1.0","query":"let nonInteractive = AADNonInteractiveUserSignInLogs\\r\\n| extend LocationDetails = parse_json(LocationDetails)\\r\\n| extend Status = parse_json(Status);\\r\\nlet data = \\r\\nunion fSigninLogs,nonInteractive|where AppDisplayName in ({Apps}) or \'*\' in ({Apps})\\r\\n|where UserDisplayName in ({Users}) \\r\\n|extend errorCode = ResultType\\r\\n|extend SigninStatus = case(errorCode == 0, \\"Success\\", errorCode == 50058, \\"Pending action (Interrupts)\\",errorCode == 50140, \\"Pending action (Interrupts)\\", errorCode == 51006, \\"Pending action (Interrupts)\\", errorCode == 50059, \\"Pending action (Interrupts)\\",errorCode == 65001, \\"Pending action (Interrupts)\\", errorCode == 52004, \\"Pending action (Interrupts)\\", errorCode == 50055, \\"Pending action (Interrupts)\\", errorCode == 50144, \\"Pending action (Interrupts)\\", errorCode == 50072, \\"Pending action (Interrupts)\\", errorCode == 50074, \\"Pending action (Interrupts)\\", errorCode == 16000, \\"Pending action (Interrupts)\\", errorCode == 16001, \\"Pending action (Interrupts)\\", errorCode == 16003, \\"Pending action (Interrupts)\\", errorCode == 50127, \\"Pending action (Interrupts)\\", errorCode == 50125, \\"Pending action (Interrupts)\\", errorCode == 50129, \\"Pending action (Interrupts)\\", errorCode == 50143, \\"Pending action (Interrupts)\\", errorCode == 81010, \\"Pending action (Interrupts)\\", errorCode == 81014, \\"Pending action (Interrupts)\\", errorCode == 81012 ,\\"Pending action (Interrupts)\\", \\"Failure\\");\\r\\ndata\\r\\n| summarize Count = count() by SigninStatus, Category\\r\\n| join kind = fullouter (datatable(SigninStatus:string)[\'Success\', \'Pending action (Interrupts)\', \'Failure\']) on SigninStatus\\r\\n| project SigninStatus = iff(SigninStatus == \'\', SigninStatus1, SigninStatus), Count = iff(SigninStatus == \'\', 0, Count), Category\\r\\n| join kind = inner (data\\r\\n    | make-series Trend = count() default = 0 on TimeGenerated from {TimeRange:start} to {TimeRange:end} step {TimeRange:grain} by SigninStatus)\\r\\n    on SigninStatus\\r\\n| project-away SigninStatus1, TimeGenerated\\r\\n| extend Status = SigninStatus\\r\\n| union (\\r\\n    data \\r\\n    | summarize Count = count() \\r\\n    | extend jkey = 1\\r\\n    | join kind=inner (data\\r\\n        | make-series Trend = count() default = 0 on TimeGenerated from {TimeRange:start} to {TimeRange:end} step {TimeRange:grain}\\r\\n        | extend jkey = 1) on jkey\\r\\n    | extend SigninStatus = \'All Sign-ins\', Status = \'*\'    \\r\\n)\\r\\n| where Category in ({Category})\\r\\n| order by Count desc\\r\\n\\r\\n\\r\\n\\r\\n","size":3,"timeContextFromParameter":"TimeRange","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces","visualization":"tiles","tileSettings":{"titleContent":{"columnMatch":"SigninStatus","formatter":1,"formatOptions":{"showIcon":true}},"leftContent":{"columnMatch":"Count","formatter":12,"formatOptions":{"palette":"blue","showIcon":true},"numberFormat":{"unit":17,"options":{"style":"decimal","maximumFractionDigits":2,"maximumSignificantDigits":3}}},"secondaryContent":{"columnMatch":"Trend","formatter":9,"formatOptions":{"min":0,"palette":"blue","showIcon":true}},"showBorder":false}},"name":"query - 5"},{"type":3,"content":{"version":"KqlItem/1.0","query":"let nonInteractive = AADNonInteractiveUserSignInLogs\\r\\n| extend LocationDetails = parse_json(LocationDetails)\\r\\n| extend Status = parse_json(Status);\\r\\nlet data = \\r\\nunion fSigninLogs,nonInteractive|where AppDisplayName in ({Apps}) or \'*\' in ({Apps})\\r\\n|where UserDisplayName in ({Users}) \\r\\n| extend ErrorCode = tostring(ResultType) \\r\\n| extend FailureReason = tostring(Status.failureReason) \\r\\n| where ErrorCode !in (\\"0\\",\\"50058\\",\\"50148\\",\\"50140\\", \\"51006\\", \\"50059\\", \\"65001\\", \\"52004\\", \\"50055\\", \\"50144\\",\\"50072\\", \\"50074\\", \\"16000\\",\\"16001\\", \\"16003\\", \\"50127\\", \\"50125\\", \\"50129\\",\\"50143\\", \\"81010\\", \\"81014\\", \\"81012\\") \\r\\n|summarize errCount = count() by ErrorCode, tostring(FailureReason), Category| sort by errCount, Category\\r\\n|project [\'❌ Error Code\'] = ErrorCode, [\'Reason\']= FailureReason, [\'Error Count\'] = toint(errCount), Category\\r\\n|where Category in ({Category});\\r\\ndata","size":1,"showAnalytics":true,"title":"Summary of top errors","timeContextFromParameter":"TimeBrush","exportFieldName":"❌ Error Code","exportParameterName":"ErrorCode","exportDefaultValue":"*","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces","visualization":"table","gridSettings":{"formatters":[{"columnMatch":"Error Count","formatter":8,"formatOptions":{"min":0,"palette":"orange","showIcon":true}}],"filter":true}},"customWidth":"67","showPin":true,"name":"query - 5"},{"type":3,"content":{"version":"KqlItem/1.0","query":"let nonInteractive = AADNonInteractiveUserSignInLogs\\r\\n| extend LocationDetails = parse_json(LocationDetails)\\r\\n| extend Status = parse_json(Status)\\r\\n| extend DeviceDetail = parse_json(DeviceDetail)\\r\\n| extend ConditionalAccessPolicies = parse_json(ConditionalAccessPolicies);\\r\\nlet data=\\r\\nunion fSigninLogs,nonInteractive\\r\\n|where AppDisplayName in ({Apps}) or \'*\' in ({Apps})\\r\\n|where UserDisplayName in ({Users}) \\r\\n| extend ErrorCode = tostring(ResultType) \\r\\n| extend FailureReason = tostring(Status.failureReason) \\r\\n| where ErrorCode !in (\\"0\\",\\"50058\\",\\"50148\\",\\"50140\\", \\"51006\\", \\"50059\\", \\"65001\\", \\"52004\\", \\"50055\\", \\"50144\\",\\"50072\\", \\"50074\\", \\"16000\\",\\"16001\\", \\"16003\\", \\"50127\\", \\"50125\\", \\"50129\\",\\"50143\\", \\"81010\\", \\"81014\\", \\"81012\\") \\r\\n| where \'{ErrorCode}\' == \'*\' or \'{ErrorCode}\' == ErrorCode\\r\\n| top 200 by TimeGenerated desc\\r\\n| extend TimeFromNow = now() - TimeGenerated\\r\\n| extend TimeAgo = strcat(case(TimeFromNow < 2m, strcat(toint(TimeFromNow / 1m), \' seconds\'), TimeFromNow < 2h, strcat(toint(TimeFromNow / 1m), \' minutes\'), TimeFromNow < 2d, strcat(toint(TimeFromNow / 1h), \' hours\'), strcat(toint(TimeFromNow / 1d), \' days\')), \' ago\')\\r\\n| project User = UserDisplayName, IPAddress, [\'❌ Error Code\'] = ErrorCode, [\'Sign-in Time\'] = TimeAgo, App = AppDisplayName, [\'Error code\'] = ErrorCode, [\'Result type\'] = ResultType, [\'Result signature\'] = ResultSignature, [\'Result description\'] = ResultDescription, [\'Conditional access policies\'] = ConditionalAccessPolicies, [\'Conditional access status\'] = ConditionalAccessStatus, [\'Operating system\'] = DeviceDetail.operatingSystem, Browser = DeviceDetail.browser, [\'Country or region\'] = LocationDetails.countryOrRegion, [\'State\'] = LocationDetails.state, [\'City\'] = LocationDetails.city, [\'Time generated\'] = TimeGenerated, Status, [\'User principal name\'] = UserPrincipalName, Category\\r\\n| where Category in ({Category});\\r\\ndata\\r\\n\\r\\n\\r\\n","size":1,"showAnalytics":true,"title":"Sign-ins with errors","timeContextFromParameter":"TimeBrush","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces","visualization":"table","gridSettings":{"formatters":[{"columnMatch":"❌ Error Code","formatter":7,"formatOptions":{"linkTarget":"GenericDetails","showIcon":true}},{"columnMatch":"App","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Error code","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Result type","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Result signature","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Result description","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Conditional access policies","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Conditional access status","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Operating system","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Browser","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Country or region","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"State","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"City","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Time generated","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Status","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"User principal name","formatter":5,"formatOptions":{"showIcon":true}}],"filter":true},"sortBy":[]},"customWidth":"33","name":"query - 5 - Copy"},{"type":3,"content":{"version":"KqlItem/1.0","query":"let nonInteractive = AADNonInteractiveUserSignInLogs\\r\\n| extend LocationDetails = parse_json(LocationDetails)\\r\\n| extend Status = parse_json(Status);\\r\\nlet data = \\r\\nunion fSigninLogs,nonInteractive|where AppDisplayName in ({Apps}) or \'*\' in ({Apps})\\r\\n|where UserDisplayName in ({Users}) \\r\\n| extend ErrorCode = tostring(ResultType) \\r\\n| extend FailureReason = Status.failureReason \\r\\n| where ErrorCode in (\\"50058\\",\\"50140\\", \\"51006\\", \\"50059\\", \\"65001\\", \\"52004\\", \\"50055\\", \\"50144\\",\\"50072\\", \\"50074\\", \\"16000\\",\\"16001\\", \\"16003\\", \\"50127\\", \\"50125\\", \\"50129\\",\\"50143\\", \\"81010\\", \\"81014\\", \\"81012\\") \\r\\n|summarize errCount = count() by ErrorCode, tostring(FailureReason), Category\\r\\n| sort by errCount\\r\\n|project [\'❌ Error Code\'] = ErrorCode, [\'Reason\'] = FailureReason, [\'Interrupt Count\'] = toint(errCount), Category\\r\\n| where Category in ({Category});\\r\\ndata","size":1,"showAnalytics":true,"title":"Summary of sign-ins waiting on user action","timeContextFromParameter":"TimeBrush","exportFieldName":"❌ Error Code","exportParameterName":"InterruptErrorCode","exportDefaultValue":"*","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces","gridSettings":{"formatters":[{"columnMatch":"Interrupt Count","formatter":8,"formatOptions":{"min":0,"palette":"orange"}}],"filter":true}},"customWidth":"67","showPin":true,"name":"query - 7"},{"type":3,"content":{"version":"KqlItem/1.0","query":"let nonInteractive = AADNonInteractiveUserSignInLogs\\r\\n| extend LocationDetails = parse_json(LocationDetails)\\r\\n| extend ConditionalAccessPolicies = parse_json(ConditionalAccessPolicies)\\r\\n| extend DeviceDetail = parse_json(DeviceDetail)\\r\\n| extend Status = parse_json(Status);\\r\\nlet data = \\r\\nunion fSigninLogs,nonInteractive \\r\\n|where AppDisplayName in ({Apps}) or \'*\' in ({Apps})\\r\\n|where UserDisplayName in ({Users}) \\r\\n| extend ErrorCode = tostring(ResultType) \\r\\n| extend FailureReason = Status.failureReason \\r\\n| where ErrorCode in (\\"50058\\",\\"50140\\", \\"51006\\", \\"50059\\", \\"65001\\", \\"52004\\", \\"50055\\", \\"50144\\",\\"50072\\", \\"50074\\", \\"16000\\",\\"16001\\", \\"16003\\", \\"50127\\", \\"50125\\", \\"50129\\",\\"50143\\", \\"81010\\", \\"81014\\", \\"81012\\") \\r\\n| where \'{InterruptErrorCode}\' == \'*\' or \'{InterruptErrorCode}\' == ErrorCode\\r\\n| top 200 by TimeGenerated desc\\r\\n| extend TimeFromNow = now() - TimeGenerated\\r\\n| extend TimeAgo = strcat(case(TimeFromNow < 2m, strcat(toint(TimeFromNow / 1m), \' seconds\'), TimeFromNow < 2h, strcat(toint(TimeFromNow / 1m), \' minutes\'), TimeFromNow < 2d, strcat(toint(TimeFromNow / 1h), \' hours\'), strcat(toint(TimeFromNow / 1d), \' days\')), \' ago\')\\r\\n| project User = UserDisplayName, IPAddress, [\'❌ Error Code\'] = ErrorCode, [\'Sign-in Time\'] = TimeAgo, App = AppDisplayName, [\'Error code\'] = ErrorCode, [\'Result type\'] = ResultType, [\'Result signature\'] = ResultSignature, [\'Result description\'] = ResultDescription, [\'Conditional access policies\'] = ConditionalAccessPolicies, [\'Conditional access status\'] = ConditionalAccessStatus, [\'Operating system\'] = DeviceDetail.operatingSystem, Browser = DeviceDetail.browser, [\'Country or region\'] = LocationDetails.countryOrRegion, [\'State\'] = LocationDetails.state, [\'City\'] = LocationDetails.city, [\'Time generated\'] = TimeGenerated, Status, [\'User principal name\'] = UserPrincipalName, Category\\r\\n| where Category in ({Category});\\r\\ndata\\r\\n\\r\\n","size":1,"showAnalytics":true,"title":"Sign-ins waiting on user action","timeContextFromParameter":"TimeBrush","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces","gridSettings":{"formatters":[{"columnMatch":"❌ Error Code","formatter":7,"formatOptions":{"linkTarget":"GenericDetails","showIcon":true}},{"columnMatch":"App","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Error code","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Result type","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Result signature","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Result description","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Conditional access policies","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Conditional access status","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Operating system","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Browser","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Country or region","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"State","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"City","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Time generated","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"Status","formatter":5,"formatOptions":{"showIcon":true}},{"columnMatch":"User principal name","formatter":5,"formatOptions":{"showIcon":true}}],"filter":true}},"customWidth":"33","showPin":true,"name":"query - 7 - Copy"}],"isLocked":false}'
    version: '1.0'
    sourceId: logAnalyticsWorkspace.id
    category: 'sentinel'
  }
}


resource analyticRuleContosoBreakGlass 'Microsoft.SecurityInsights/alertRules@2023-02-01-preview' = {
  scope: logAnalyticsWorkspace
  dependsOn: [
    sentinel
  ]
  name: contosoBreakGlassAlertId
  kind: 'Scheduled'
  properties: {
    alertDetailsOverride: {
      alertDisplayNameFormat: 'User {{alertNumber}} | ${contosoBreakGlassAlertName} '
      alertDescriptionFormat: 'The break glass account has been logged into from IPAddress: {{IPAddress}}'
    }
    description: 'This alert triggers any time that a break glass is used'
    displayName: contosoBreakGlassAlertName
    enabled: true
    entityMappings: [
      {
        entityType: 'Account'
        fieldMappings: [
          {
            columnName: 'UserDisplayName'
            identifier: 'DisplayName'
          }
          {
            columnName: 'UserPrincipalName'
            identifier: 'FullName'
          }
        ]
      }
      {
        entityType: 'IP'
        fieldMappings: [
          {
            columnName: 'IPAddress'
            identifier: 'Address'
          }
        ]
      }
    ]
    eventGroupingSettings: {
      aggregationKind: 'AlertPerResult'
    }
    incidentConfiguration: {
      createIncident: true
      groupingConfiguration: {
        enabled: true
        lookbackDuration: 'PT5H'
        matchingMethod: 'Selected'
        reopenClosedIncident: false
        groupByCustomDetails: [
          'User'
        ]
      }
    }
    customDetails: {
      User: 'alertNumber'
    }
    query: 'fSigninLogs\r\n| where UserPrincipalName =~ "BreakGlass@contoso.com"\r\n| extend alertNumber = range(1,${numberOfAnalyticRules})\r\n| mv-expand alertNumber'
    queryFrequency: 'PT1H'
    queryPeriod: 'P14D'
    severity: 'Informational'
    suppressionDuration: 'P1D'
    suppressionEnabled: true
    tactics: [
      'InitialAccess'
    ]
    techniques: [
      'T1078'
    ]
    triggerOperator: 'GreaterThan'
    triggerThreshold: 0
  }
}

resource AutomationRule 'Microsoft.SecurityInsights/automationRules@2022-12-01-preview' = {
  scope: logAnalyticsWorkspace
  name: guid(AutomationRuleName)
  properties: {
    displayName: 'Demo: Add Tasks To Contoso Break Glass Incident'
    order: 1
    triggeringLogic: {
      isEnabled: true
      triggersOn: 'Incidents'
      triggersWhen: 'Created'
      conditions: [
        {
          conditionType: 'Property'
          conditionProperties: {
            propertyName: 'IncidentProviderName'
            operator: 'Equals'
            propertyValues: [
              'Azure Sentinel'
            ]
          }
        }
        {
          conditionType: 'Property'
          conditionProperties: {
            propertyName: 'IncidentRelatedAnalyticRuleIds'
            operator: 'Contains'
            propertyValues: [
              analyticRuleContosoBreakGlass.id
            ]
          }
        }
      ]
    }
    actions: [
      {
        order: 1
        actionType: 'AddIncidentTask'
        actionConfiguration: {
          title: 'Complete Lab 01'
          description: '<div>As an analyst, your primary goal will be responding to and investigating incidents created within Microsoft Sentinel. In this section we will review an incident that has occurred. You will assign the incident to yourself and go through the details that are provided within the incident, drilling down into the events and investigation.</div><div><br></div><div><a href="https://github.com/TheAlistairRoss/MicrosoftSentinel/tree/main/Labs/Analysts%20Introduction%20Workshop/Labs/LAB01" rel="noopener noreferrer" target="_blank" style="color: var(--colorLink);">MicrosoftSentinel/Labs/Analysts Introduction Workshop/Labs/LAB01 at main | TheAlistairRoss/MicrosoftSentinel (github.com)</a></div>'
        }
      }
      {
        order: 2
        actionType: 'AddIncidentTask'
        actionConfiguration: {
          title: 'Complete Lab 02'
          description: '<div>As an analyst, visual aids can provide greater insights to what is going on with your data. Use Azure workbooks to analyse the logs.</div><div><br></div><div><a href="https://github.com/TheAlistairRoss/MicrosoftSentinel/blob/main/Labs/Analysts%20Introduction%20Workshop/Labs/LAB02/README.MD" rel="noopener noreferrer" target="_blank" style="color: var(--colorLink);">MicrosoftSentinel/README.MD at main | TheAlistairRoss/MicrosoftSentinel (github.com)</a></div>'
        }
      }
      {
        order: 3
        actionType: 'AddIncidentTask'
        actionConfiguration: {
          title: 'Complete Lab 03'
          description: '<div>All logs within Microsoft Sentinel are queried and accessed using Kusto Query Language, whether that is via a workbook, GUI, API or directly. In this exercise we will explore events within the logs and enrich and existing incident with bookmarks.</div><div><br></div><div><a href="https://github.com/TheAlistairRoss/MicrosoftSentinel/blob/main/Labs/Analysts%20Introduction%20Workshop/Labs/LAB03/README.MD" rel="noopener noreferrer" target="_blank">MicrosoftSentinel/README.MD at main | TheAlistairRoss/MicrosoftSentinel (github.com)</a></div>'
        }
      }
      {
        order: 4
        actionType: 'AddIncidentTask'
        actionConfiguration: {
          title: 'Complete Lab 04'
          description: '<div>Once a decision has been made, action needs to be taken. Whether that is responding to the threat or closing the alert.</div><div><br></div><div><a href="https://github.com/TheAlistairRoss/MicrosoftSentinel/blob/main/Labs/Analysts%20Introduction%20Workshop/Labs/LAB04/README.MD" rel="noopener noreferrer" target="_blank">MicrosoftSentinel/README.MD at main | TheAlistairRoss/MicrosoftSentinel (github.com)</a></div>'
        }
      }
    ]
  }
}

resource MicrosoftSentinelConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: MicrosoftSentinelConnectionName
  location: location
  kind: 'V1'
  properties: {
    displayName: MicrosoftSentinelConnectionName
    customParameterValues: {
    }
    parameterValueType: 'Alternative'
    api: {
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/azuresentinel'
    }
  }
}

resource playbookDemoDisableUserAccount 'Microsoft.Logic/workflows@2019-05-01' = {
  name: playbookDemoDisableUserAccountName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {
          }
          type: 'Object'
        }
      }
      triggers: {
        Microsoft_Sentinel_entity: {
          type: 'ApiConnectionWebhook'
          inputs: {
            body: {
              callback_url: '@{listCallbackUrl()}'
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azuresentinel\'][\'connectionId\']'
              }
            }
            path: '/entity/@{encodeURIComponent(\'Account\')}'
          }
        }
      }
      actions: {
        'Add_comment_to_incident_(V3)': {
          runAfter: {
          }
          type: 'ApiConnection'
          inputs: {
            body: {
              incidentArmId: '@triggerBody()?[\'IncidentArmID\']'
              message: '<p><strong>Demo<br>\n</strong><br>\n<strong>User</strong> : \'@{triggerBody()?[\'Entity\']?[\'properties\']?[\'Name\']}\' has been locked out and manager notified<br>\n<br>\n<strong>This is a demo comment added by the Azure Logic Apps. No Action has been taken.</strong></p>'
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azuresentinel\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/Incidents/Comment'
          }
        }
      }
      outputs: {
      }
    }
    parameters: {
      '$connections': {
        value: {
          azuresentinel: {
            connectionId: MicrosoftSentinelConnection.id
            connectionName: 'azuresentinel-${MicrosoftSentinelConnectionName}'
            connectionProperties: {
              authentication: {
                type: 'ManagedServiceIdentity'
              }
            }
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/azuresentinel'
          }
        }
      }
    }
  }
}

resource monitoringMetricsRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: resourceGroup()
  name:  guid(applicationObjectId, monitoringMetricsPublisherRoleId, resourceGroup().name)
  properties: {
    roleDefinitionId: resourceId('microsoft.authorization/roleDefinitions', monitoringMetricsPublisherRoleId)
    principalId: applicationObjectId
    principalType: 'ServicePrincipal'
  }
}

resource sentinelAutomationRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: resourceGroup()
  name:  guid(azureSecurityInsightsObjectId, microsoftSentinelAutomationContributorRoleId, resourceGroup().name)
  properties: {
    roleDefinitionId: resourceId('microsoft.authorization/roleDefinitions', microsoftSentinelAutomationContributorRoleId)
    principalId: applicationObjectId
    principalType: 'ServicePrincipal'
  }
}

resource sentinelContributorGroupRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: resourceGroup()
  name:  guid(userGroupId, microsoftSentinelContributorRoleId, resourceGroup().name)
  properties: {
    roleDefinitionId: resourceId('microsoft.authorization/roleDefinitions', microsoftSentinelContributorRoleId)
    principalId: userGroupId
    principalType: 'Group'
  }
}

resource logicAppContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: resourceGroup()
  name:   guid(userGroupId, microsoftLogicAppContributorRoleId, resourceGroup().name)
  properties: {
    roleDefinitionId: resourceId('microsoft.authorization/roleDefinitions', microsoftLogicAppContributorRoleId)
    principalId: userGroupId
    principalType: 'Group'
  }
}


resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: resourceGroup()
  name:  guid('${resourceGroup().id}/providers/Microsoft.Logic/workflows/${playbookDemoDisableUserAccountName}', microsoftSentinelAutomationContributorRoleId, resourceGroup().name)
  properties: {
    roleDefinitionId: resourceId('microsoft.authorization/roleDefinitions', microsoftSentinelResponderRoleId)
    principalId:  playbookDemoDisableUserAccount.identity.principalId
    principalType: 'ServicePrincipal'
  }
}


output DCEIngestionEndpoint string = dataCollectionEndpoint.properties.logsIngestion.endpoint
output DCRImmutableId string = dataCollectionRule.properties.immutableId
output StreamName string = 'Custom-${customSigninLogsTable.name}'
