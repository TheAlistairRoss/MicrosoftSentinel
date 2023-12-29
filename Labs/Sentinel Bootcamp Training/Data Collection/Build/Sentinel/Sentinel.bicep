@description('Location of the resources')
param location string = resourceGroup().location
param basename string = 'sent-adv-logging-workshop'
var workspaceName = '${basename}-wksp'


resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
name: workspaceName
location: location
}

resource sentinel 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'SecurityInsights(${workspaceName})'
  location: location
  plan: {
    name: 'SecurityInsights(${workspaceName})'
    promotionCode: ''
    product: 'OMSGallery/SecurityInsights'
    publisher: 'Microsoft'
  }
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
  }
}


output workspaceId string = logAnalyticsWorkspace.id
