targetScope = 'subscription'

@description('Azure Region')
param location string = 'uksouth'

@minLength(5)
@maxLength(40)
param basename string = 'sent-chatsnhacks-workshop'

@description('Start of the Ip Address range for the Vnet. It must end with a .0 as this is using a /24 subnet mask (e.g. 10.0.0.0)') 
@minLength(7)
@maxLength(13)
param vnetAddressIpV4Id string = '10.0.0.0'

param adminUsername string = 'workshopadmin'
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'password'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrSSHKey string

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param _artifactsLocation string = deployment().properties.templateLink.uri

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param _artifactsLocationSasToken string = ''


var resourceGroupName = '${basename}-sentinel-rg'

resource SentinelResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
}

module NetworkingDeployment 'Network/Networking.bicep' = {
  name: '${basename}-Networking-Deployment'
  scope: SentinelResourceGroup
  params: {
    basename: basename
    location: location
    vnetName: '${basename}-vnet'
    vnetAddressIpV4Id: vnetAddressIpV4Id
  }
}

module SentinelDeployment 'Sentinel/Sentinel.bicep' = {
  name: '${basename}-Sentinel-Deployment'
  scope: SentinelResourceGroup
  params: {
    basename: basename
    location: location
  }
}

module DataCollectionRuleDeployment 'Sentinel Data Collection/DataCollectionRules.bicep' = {
  name: '${basename}-Data-Collection-Rule-Deployment'
  scope: SentinelResourceGroup
  params: {
    basename: basename
    location: location
    workspaceResourceId: SentinelDeployment.outputs.workspaceId
  }
}

module LogSourceDeployment 'LinuxLogSource/LogSource.bicep' = {
  name: '${basename}-Log-Source-Deployment'
  scope: SentinelResourceGroup
  dependsOn: [
    NetworkingDeployment
  ]
  params: {
    location: location
    vmName: basename
    adminUsername: adminUsername
    authenticationType: authenticationType
    adminPasswordOrKey: adminPasswordOrSSHKey
    ubuntuOSVersion: 'Ubuntu-2004'
    securityType: 'TrustedLaunch'
    vmSize: 'Standard_D2s_v3'
    subnetResourceId: NetworkingDeployment.outputs.LogSourceSubnetResourceId
    _artifactsLocation: _artifactsLocation
    _artifactsLocationSasToken: _artifactsLocationSasToken

  }
}
