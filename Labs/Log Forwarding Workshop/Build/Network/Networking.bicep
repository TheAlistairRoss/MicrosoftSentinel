@description('Location of the resources')
param location string = resourceGroup().location

param basename string = 'sent-adv-logging-workshop'

@description('Name for Log Source and Log Forwarder Vnets')
param vnet1Name string = 'logging-vnet'

@description('Name for vNet 2')
param vnet2Name string = 'sentinel-vnet'

@allowed([
  'Open'
  'Closed'
])
param amplsQueryAccessMode string = 'Open'

@allowed([
  'Open'
  'Closed'
])
param amplsIngestionAccessMode string = 'Open'

var vnet1Config = {
  addressSpacePrefix: '10.0.0.0/24'
  subnets: [
    {
      name: 'logSource'
      addressPrefix: '10.0.0.0/25'
    }
    {
      name: 'logForwarder'
      addressPrefix: '10.0.0.0/25'
    }
  ]
}

var vnet2Config = {
  addressSpacePrefix: '10.0.1.0/24'
  subnets: [
    {
      name: 'default'
      addressPrefix: '10.0.1.0/24'
    }
  ]
}

resource vnet1 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnet1Name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet1Config.addressSpacePrefix
      ]
    }
  }
}

resource vnet1_subnets 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = [for subnet in vnet1Config.subnets: {
  name: subnet.name
  properties: {
    addressPrefix: subnet.addressPrefix
  }
  parent: vnet1
}
]

resource vnet2 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnet2Name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet2Config.addressSpacePrefix
      ]
    }
  }
}

resource vnet2_subnets 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = [for subnet in vnet2Config.subnets: {
  name: subnet.name
  properties: {
    addressPrefix: subnet.addressPrefix
  }
  parent: vnet2
}
]

resource vnet1Tovnet2Peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  parent: vnet1
  name: '${vnet1Name}-${vnet2Name}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnet2.id
    }
  }
}

resource vnet2Tovnet1Peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  parent: vnet2
  name: '${vnet2Name}-${vnet1Name}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnet1.id
    }
  }
}

// DNS
var privateDnsZoneNames = [
  'privatelink.monitor.azure.com'
  'privatelink.oms.opinsights.azure.com'
  'privatelink.oms.opinsights.azure.com'
  'privatelink.agentsvc.azure-automation.net'
  'privatelink.blob.${environment().suffixes.storage}'
]

var privateEndpointName = '${basename}-private-endpoint'

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' = [for privateDnsZoneName in privateDnsZoneNames: {
  name: privateDnsZoneName
  location: 'global'
  tags: {}
  properties: {}
}
]

resource privateDnsZoneLinkToVnet1 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = [for privateDnsZoneName in privateDnsZoneNames: {
  name: '${privateDnsZoneName}/${uniqueString(vnet1.id)}'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnet1.id
    }
    registrationEnabled: true
  }
}
]

resource azureMonitorPrivateLinkScope 'microsoft.insights/privatelinkscopes@2021-07-01-preview' = {
  name: '${basename}-ampls'
  location: location
  properties: {
    accessModeSettings: {
      queryAccessMode: amplsQueryAccessMode
      ingestionAccessMode: amplsIngestionAccessMode
      exclusions: []
    }
  }
}

resource privateEndpointDefaultDnsZoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  name: '${privateEndpointName}/default'
  properties: {
    privateDnsZoneConfigs: [for privateDnsZoneName in privateDnsZoneNames: {
      name: privateDnsZoneName
      properties: {
        privateDnsZoneId: reference(privateDnsZoneName).id
      }
    }
    ]
  }
}

output AMPLSResourceId string = azureMonitorPrivateLinkScope.id
output LogSourceSubnetResourceId string = '${vnet1.id}/subnets/${vnet1Config.subnets[0].name}'
output LogForwarderSubnetResourceId string = '${vnet1.id}/subnets/${vnet1Config.subnets[1].name}'
output SentinelSubnetResourceId string = '${vnet2.id}/subnets/${vnet2Config.subnets[0].name}'
