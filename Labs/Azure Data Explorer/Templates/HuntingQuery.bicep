param workspaceName string = 'myworkspace'
param ADXDatabaseUri string = 'https://help.uksouth.kusto.windows.net/kustodb'

resource workspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' existing = {
  name: workspaceName
}

resource HuntingQuery_c1e7abe2_e74c_4789_a161_bd0186cb21af 'Microsoft.OperationalInsights/workspaces/savedSearches@2020-08-01' = {
  parent: workspace
  name: 'c1e7abe2-e74c-4789-a161-bd0186cb21af'
  properties: {
    category: 'Hunting Queries'
    displayName: 'ADX POC: Sign-ins from IPs that attempt sign-ins to disabled accounts'
    version: 2
    query: 'let Frequency = 6h;\r\nlet failed_signins = \r\n//table(tableName)\r\nunion \r\nadx("${ADXDatabaseUri}").SigninLogs,\r\nadx("${ADXDatabaseUri}").AADNonInteractiveUserSignInLogs\r\n| where TimeGenerated > ago(Frequency)\r\n| where ResultType == "50057"\r\n| where ResultDescription == "User account is disabled. The account has been disabled by an administrator.";\r\nlet disabled_users = failed_signins\r\n| summarize by UserPrincipalName;\r\n//table(tableName)\r\nunion \r\nadx("${ADXDatabaseUri}").SigninLogs,\r\nadx("${ADXDatabaseUri}").AADNonInteractiveUserSignInLogs\r\n| where TimeGenerated > ago(Frequency)\r\n| where ResultType == 0\r\n| where isnotempty(UserPrincipalName)\r\n| where UserPrincipalName !in (disabled_users)\r\n| summarize\r\nsuccessfulAccountsTargettedCount = dcount(UserPrincipalName),\r\nsuccessfulAccountSigninSet = make_set(UserPrincipalName, 100),\r\nsuccessfulApplicationSet = make_set(AppDisplayName, 100)\r\nby IPAddress, Type\r\n// Assume IPs associated with sign-ins from 100+ distinct user accounts are safe\r\n| where successfulAccountsTargettedCount < 50\r\n| where isnotempty(successfulAccountsTargettedCount)\r\n| join kind=inner (failed_signins\r\n| summarize\r\nStartTime = min(TimeGenerated),\r\nEndTime = max(TimeGenerated),\r\ntotalDisabledAccountLoginAttempts = count(),\r\ndisabledAccountsTargettedCount = dcount(UserPrincipalName),\r\napplicationsTargeted = dcount(AppDisplayName),\r\ndisabledAccountSet = make_set(UserPrincipalName, 100),\r\ndisabledApplicationSet = make_set(AppDisplayName, 100)\r\nby IPAddress, Type\r\n| order by totalDisabledAccountLoginAttempts desc)\r\non IPAddress\r\n| project\r\nStartTime,\r\nEndTime,\r\nIPAddress,\r\ntotalDisabledAccountLoginAttempts,\r\ndisabledAccountsTargettedCount,\r\ndisabledAccountSet,\r\ndisabledApplicationSet,\r\nsuccessfulApplicationSet,\r\nsuccessfulAccountsTargettedCount,\r\nsuccessfulAccountSigninSet,\r\nType\r\n| order by totalDisabledAccountLoginAttempts\r\n| join kind=leftouter (\r\nBehaviorAnalytics\r\n| where ActivityType in ("FailedLogOn", "LogOn")\r\n| where EventSource =~ "Azure AD"\r\n| project\r\nUsersInsights,\r\nDevicesInsights,\r\nActivityInsights,\r\nInvestigationPriority,\r\nSourceIPAddress,\r\nUserPrincipalName\r\n| project-rename IPAddress = SourceIPAddress\r\n| summarize\r\nUsers = make_set(UserPrincipalName, 100),\r\nUsersInsights = make_set(UsersInsights, 100),\r\nDevicesInsights = make_set(DevicesInsights, 100),\r\nIPInvestigationPriority = sum(InvestigationPriority)\r\nby IPAddress\r\n)\r\non IPAddress\r\n| extend SFRatio = toreal(toreal(disabledAccountsTargettedCount) / toreal(successfulAccountsTargettedCount))\r\n| where SFRatio >= 0.5\r\n| sort by IPInvestigationPriority desc'
    tags: [
      {
        name: 'description'
        value: 'ADX POC: Based on the original analytic rule found here: https://github.com/Azure/Azure-Sentinel/blob/master/Solutions/Microsoft%20Entra%20ID/Analytic%20Rules/SigninAttemptsByIPviaDisabledAccounts.yaml.'
      }
    ]
  }
}