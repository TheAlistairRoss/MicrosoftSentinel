// Parameters

@description('Resources Name Prefix. This will be used to name most of the resources and the resource group')
param basename string = 'sentinel-workshop'


@description('Resource Id of the Azure Bastion Subnet')
param subnetResourceId string 

@description('Location of the resources')
param location string = resourceGroup().location

// Variables

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
            id: subnetResourceId 
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
}
