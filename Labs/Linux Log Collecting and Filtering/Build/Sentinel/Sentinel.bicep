
@description('Name of the Log Analytics Workspace. This will be used to name the Log Analytics Workspace and the Sentinel Solution.')
param workspaceName string 

@description('Location of the resources')
param location string = resourceGroup().location

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
name: workspaceName
location: location
}

resource sentinel 'Microsoft.SecurityInsights/onboardingStates@2023-02-01-preview' = {
  name: 'default'
  scope: logAnalyticsWorkspace
  properties: {}
}

