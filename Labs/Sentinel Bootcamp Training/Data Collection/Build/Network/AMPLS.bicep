param basename string = 'sentinel-bootcamp'
param location string = resourceGroup().location

@description('The resource ID of the virtual network')
param virtualNetworkId string

@description('The name of the subnet to use for the private endpoint')
param privateEndpointSubnetName string

var amplsName = '${basename}-ampls'
var amplsQueryAccessMode = 'Enabled'
var amplsIngestionAccessMode = 'Enabled'
var privateEndpointSubnetResourceId = '${virtualNetworkId}/subnets/${privateEndpointSubnetName}'
var privateEndpointName = '${basename}-ampls-privateEndpoint'
var privateEndpointNICName = '${privateEndpointName}-nic'

var DNSZones = [
  'privatelink.monitor.azure.com'
  'privatelink.oms.opinsights.azure.com'
  'privatelink.ods.opinsights.azure.com'
  'privatelink.agentsvc.azure-automation.net'
  'privatelink.blob.${environment().suffixes.storage}'
]

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
      id: privateEndpointSubnetResourceId
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
