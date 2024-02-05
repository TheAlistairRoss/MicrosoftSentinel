// Parameters
@description('Resources Name Prefix. This will be used to name most of the resources')
param basename string = 'sentinel-workshop'

@description('Location of the resources')
param location string = resourceGroup().location

@description('Name for the Log Source Subnet')
param logSourceSubnetName string = 'logSourceSubnet'

@description('Start of the Ip Address range for the Vnet. It must end with a .0 as this is using a /24 subnet mask (e.g. 10.0.0.0)')
param vnetAddressIpV4Id string = '10.0.0.0'

@description('Name for the virtual network')
param vnetName string = '${basename}-vnet'

// Variables

var bastionSubnetNSGName = '${basename}-AzureBastionSubnet-nsg'

var logSourceSubnetNSGName = '${basename}-${logSourceSubnetName}-nsg'

var vnetAddressIPv4 = substring(vnetAddressIpV4Id, 0, lastIndexOf(vnetAddressIpV4Id, '.'))

var vnetConfig = {
  addressSpacePrefix: '${vnetAddressIPv4}.0/24'
  subnets: {
    azureBastionSubnet: {
      name: 'AzureBastionSubnet'
      addressPrefix: '${vnetAddressIPv4}.0/26'
    }
    logSourceSubnet: {
      name: logSourceSubnetName
      addressPrefix: '${vnetAddressIPv4}.64/27'
    }
  }
}

// Resources
// Resources - Network Security Groups

resource bastionSubnetNSG 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
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

resource logSourceSubnetNSG 'Microsoft.Network/networkSecurityGroups@2023-06-01' = {
  name: logSourceSubnetNSGName
  location: location
  properties: {
    securityRules: []
  }
}

// Resources - Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetConfig.addressSpacePrefix
      ]
    }
    subnets: [
      {
        name: vnetConfig.subnets.azureBastionSubnet.name
        properties: {
          addressPrefix: vnetConfig.subnets.azureBastionSubnet.addressPrefix
          networkSecurityGroup: {
            id: bastionSubnetNSG.id
          }
        }
      }
      {
        name: vnetConfig.subnets.logSourceSubnet.name
        properties: {
          addressPrefix: vnetConfig.subnets.logSourceSubnet.addressPrefix
          networkSecurityGroup: {
            id: logSourceSubnetNSG.id
          }
        }
      }
    ]
  }
}
