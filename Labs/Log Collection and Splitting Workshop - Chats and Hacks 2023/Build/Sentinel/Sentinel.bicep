@description('Location of the resources')
param location string = resourceGroup().location
param basename string = 'sent-adv-logging-workshop'
param deployDataCollectionEndpoint bool = false
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

resource dataCollectionEndpoint 'Microsoft.Insights/dataCollectionEndpoints@2022-06-01' = if (deployDataCollectionEndpoint) { 
  name: '${basename}-dce'
  location: location
  properties: {
    networkAcls: {
      publicNetworkAccess: 'Disabled'
    }
  }
}

output workspaceId string = logAnalyticsWorkspace.id
output dataCollectionEndpointId string = (deployDataCollectionEndpoint) ? dataCollectionEndpoint.id : ''
