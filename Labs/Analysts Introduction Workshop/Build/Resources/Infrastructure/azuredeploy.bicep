param workspaceName string

param location string = resourceGroup().location

var labSuffix = '-DemoLab'
@description('DCE name must be between 3-44 chars long and unique within the resource group')

var dataCollectionEndpointName = (length(workspaceName) - length(labSuffix)) >= 44 ? '${substring(workspaceName, 44 -length(labSuffix))}${labSuffix}' : '${workspaceName}${labSuffix}'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
}

resource sentinel 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: workspaceName
  location: location
  plan: {
    name: workspaceName
    publisher: 'Microsoft'
    promotionCode: ''
    product: 'OMSGallery/SecurityInsights'
  }
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
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
