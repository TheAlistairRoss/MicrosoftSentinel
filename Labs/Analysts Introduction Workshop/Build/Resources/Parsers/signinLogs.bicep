param workspaceName string

var signinLogsFunctionAlias = 'demoSigninlogs'

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}


resource customSigninLogsFunction 'Microsoft.OperationalInsights/workspaces/savedSearches@2020-08-01' = {
  parent: workspace
  name: toLower(signinLogsFunctionAlias)
  properties: {
    etag: '*'
    category: 'Demo'
    displayName: signinLogsFunctionAlias
    query: 'union isfuzzy=true SigninLogs, SigninLogs_CL'
    functionAlias: signinLogsFunctionAlias
  }
}
