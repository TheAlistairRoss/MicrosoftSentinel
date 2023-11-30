@description('Location of the resources')
param location string = resourceGroup().location

@description('Log Analytics Workspace Resource Id')
param workspaceResourceId string

@minLength(5)
@maxLength(40)
param basename string = 'sent-adv-logging-workshop'

resource cefDataCollectionRule 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: '${basename}-cef-dcr'
  location: location
  kind: 'Linux'
  properties: {
    dataSources: {
      syslog: [
        {
          streams: [
            'Microsoft-CommonSecurityLog'
          ]
          facilityNames: [
            'user'
            'auth'
            'authpriv'
          ]
          logLevels: [
            'Info'
            'Notice'
            'Warning'
            'Error'
            'Critical'
            'Alert'
            'Emergency'
          ]
          name: 'sysLogsDataSource'
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: workspaceResourceId
          name: 'DataCollectionEvent'
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-CommonSecurityLog'
        ]
        destinations: [
          'DataCollectionEvent'
        ]
      }
    ]
  }
}
