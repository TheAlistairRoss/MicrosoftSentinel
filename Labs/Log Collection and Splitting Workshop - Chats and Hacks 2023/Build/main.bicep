targetScope = 'subscription'

@description('Azure Region')
param location string = 'uksouth'

@minLength(5)
@maxLength(40)
param basename string = 'sent-adv-logging-workshop'

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

param deployNetworks bool = true
param deploySentinel bool = true
param deployLinuxLogSource bool = true
param deployDataCollectionRule bool = true

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param _artifactsLocation string = deployment().properties.templateLink.uri

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param _artifactsLocationSasToken string = ''

var logSourceResourceGroupName = '${basename}-log-source-rg'
var NetworkingResourceGroupName = '${basename}-networking-rg'
var SentinelResourceGroupName = '${basename}-sentinel-rg'

resource logSourceResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = if (deployNetworks && deployLinuxLogSource) { 
  name: logSourceResourceGroupName
  location: location
}

resource NetworkingResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = if (deployNetworks) {
  name: NetworkingResourceGroupName
  location: location
}

resource SentinelResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = if (deploySentinel) {
  name: SentinelResourceGroupName
  location: location
}

module NetworkingDeployment 'Network/Networking.bicep' = if (deployNetworks) {
  name: '${basename}-Networking-Deployment'
  scope: NetworkingResourceGroup
  params: {
    basename: basename
    location: location
    vnetName: '${basename}-vnet'
  }
}

module SentinelDeployment 'Sentinel/Sentinel.bicep' = if (deploySentinel) {
  name: '${basename}-Sentinel-Deployment'
  scope: SentinelResourceGroup
  params: {
    basename: basename
    location: location
  }
}

module DataCollectionRuleDeployment 'Sentinel Data Collection/DataCollectionRules.bicep' = if (deployDataCollectionRule && deploySentinel) {
  name: '${basename}-Data-Collection-Rule-Deployment'
  scope: SentinelResourceGroup
  params: {
    basename: basename
    location: location
    workspaceResourceId: SentinelDeployment.outputs.workspaceId
  }
}

module LogSourceDeployment 'LinuxLogSource/LogSource.bicep' = if ((deployNetworks) && (deployLinuxLogSource)) {
  name: '${basename}-Log-Source-Deployment'
  scope: logSourceResourceGroup
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
