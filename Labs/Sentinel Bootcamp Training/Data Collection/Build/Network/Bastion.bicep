@description('Location of the resources')
param location string = resourceGroup().location

param basename string = 'sentinel-bootcamp'

@description('Resource Id of the Azure Bastion Subnet')
param bastionVnetSubnetResourceId string 

var bastionHostName = '${basename}-bastion'
var publicIpAddressName = '${bastionHostName}-pip'


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
            id: bastionVnetSubnetResourceId 
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
}
