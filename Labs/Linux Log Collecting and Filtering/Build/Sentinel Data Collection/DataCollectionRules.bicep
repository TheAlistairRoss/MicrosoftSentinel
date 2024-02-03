@minLength(5)
@maxLength(40)
param basename string = 'sentinel-workshop'

@description('Location of the resources')
param location string = resourceGroup().location

@description('Log Analytics Workspace Resource Id')
param workspaceResourceId string

resource syslogDataCollectionRule 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: '${basename}-syslog-dcr'
  location: location
  kind: 'Linux'
  properties: {
    dataSources: {
      syslog: [
        {
          streams: [
            'Microsoft-Syslog'
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
          'Microsoft-Syslog' 
        ]
        destinations: [
          'DataCollectionEvent'
        ]
      }
    ]
  }
}

output syslogDcrResourceId string = syslogDataCollectionRule.id
