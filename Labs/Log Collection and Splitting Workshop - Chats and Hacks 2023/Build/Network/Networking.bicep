@description('Location of the resources')
param location string = resourceGroup().location

param basename string = 'sent-adv-logging-workshop'

@description('Name for Log Source and Log Forwarder Vnets')
param vnetName string = '${basename}-logging-vnet'

@description('Start of the Ip Address range for the Vnet. It must end with a .0 as this is using a /24 subnet mask (e.g. 10.0.0.0)') 
param vnetAddressIPv4Id string = '10.0.0.0'

// Remove the last octet from the IP address
//var vnetAddressIPv4 = vnetAddressIPv4Id.split('.').slice(0,3).join('.')

var vnetAddressIPv4 = substring(vnetAddressIPv4Id,0, lastIndexOf(vnetAddressIPv4Id, '.') -1)

var vnetConfig = {
  addressSpacePrefix: '${vnetAddressIPv4}.0/24'
  subnets: [
    {
      name: 'AzureBastionSubnet'
      addressPrefix: '${vnetAddressIPv4}.0/25'
    }
    {
      name: 'logSource'
      addressPrefix: '${vnetAddressIPv4}.128/25'
    }
  ]
}

var bastionHostName = '${basename}-bastion'
var bastionSubnetNSGName = '${bastionHostName}-nsg'
var publicIpAddressName = '${bastionHostName}-pip'


resource bastionSubnetNSG 'Microsoft.Network/networkSecurityGroups@2022-07-01' =  {
  name: bastionSubnetNSGName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowHttpsInBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowGatewayManagerInBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'GatewayManager'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowLoadBalancerInBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowBastionHostCommunicationInBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowSshRdpOutBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRanges: [
            '22'
            '3389'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowAzureCloudCommunicationOutBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '443'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 110
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowBastionHostCommunicationOutBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 120
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowGetSessionInformationOutBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          destinationPortRanges: [
            '80'
            '443'
          ]
          access: 'Allow'
          priority: 130
          direction: 'Outbound'
        }
      }
      {
        name: 'DenyAllOutBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  dependsOn: [
    bastionSubnetNSG
  ]
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetConfig.addressSpacePrefix
      ]
    }
  }
}

resource vnetBastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  name: vnetConfig.subnets[0].name
  properties: {
    networkSecurityGroup: {
      id: bastionSubnetNSG.id
    }
    addressPrefix: vnetConfig.subnets[0].addressPrefix
  }
  parent: vnet
}

resource vnetLogSourceSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' =  {
  name: vnetConfig.subnets[1].name
  properties: {
    addressPrefix: vnetConfig.subnets[1].addressPrefix
  }
  parent: vnet
}


resource publicIp 'Microsoft.Network/publicIPAddresses@2022-07-01' =  {
  name: publicIpAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2022-07-01' = {
  name: bastionHostName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: vnetBastionSubnet.id 
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
}

output LogSourceSubnetResourceId string = vnetLogSourceSubnet.id
