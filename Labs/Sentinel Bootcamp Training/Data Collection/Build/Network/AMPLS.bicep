// Parameters

@description('Resources Name Prefix. This will be used to name most of the resources and the resource group')
param basename string = 'sentinel-bootcamp'


@description('Location of the resources')
param location string = resourceGroup().location

@description('The ResourceId of the subnet to use for the virtual machine')
param subnetResourceId string

// Variables
var amplsName = '${basename}-ampls'

var amplsIngestionAccessMode = 'Enabled'

var amplsQueryAccessMode = 'Enabled'

var DNSZones = [
  'privatelink.monitor.azure.com'
  'privatelink.oms.opinsights.azure.com'
  'privatelink.ods.opinsights.azure.com'
  'privatelink.agentsvc.azure-automation.net'
  'privatelink.blob.${environment().suffixes.storage}'
]

var privateEndpointName = '${basename}-ampls-privateEndpoint'

var privateEndpointNICName = '${privateEndpointName}-nic'

var virtualNetworkId = substring(subnetResourceId, 0, indexOf(subnetResourceId, '/subnets/ '))

// Resources

resource ampls 'microsoft.insights/privatelinkscopes@2021-07-01-preview' = {
  name: amplsName
  location: 'global'
  properties: {
    accessModeSettings: {
      queryAccessMode: amplsQueryAccessMode
      ingestionAccessMode: amplsIngestionAccessMode
      exclusions: []
    }
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: privateEndpointName
  location: location
  tags: {}
  properties: {
    subnet: {
      id: subnetResourceId
    }
    customNetworkInterfaceName: privateEndpointNICName
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          // AMPLS Resource ID
          privateLinkServiceId: ampls.id
          groupIds: [
            'azuremonitor'
          ]
        }
      }
    ]
  }
}

resource privateDNSZones 'Microsoft.Network/privateDnsZones@2018-09-01' = [for DNSZone in DNSZones: {
  name: DNSZone
  location: 'global'
  tags: {}
  properties: {}
}
]

resource privatelink_virtualNetworkIds 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = [for DNSZone in DNSZones: {
  name: '${DNSZone}/${uniqueString(virtualNetworkId)}'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: virtualNetworkId
    }
    registrationEnabled: false
  }
}
]

resource amplsPrivateEndpoint 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [for (DNSZone, i) in DNSZones: {
      name: DNSZone
      properties: {
        privateDnsZoneId: privateDNSZones[i].id
      }
    }
    ]
  }
}
