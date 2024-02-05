

@description('SSH Key or password for the Virtual Machine.')
@secure()
param adminPasswordOrSSHKey string = 'WorkshopPassword1234'

@description('Username for the Virtual Machine.')
param adminUsername string = 'workshopadmin'

@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'password'

@minLength(5)
@maxLength(40)
param basename string = 'sentinel-workshop'


@description('Current UTC Datetime in the format YYYYMMDDhhmmss')
param datetime string = utcNow()

param deployBastion bool = true
param deployDataCollectionRule bool = true
param deployLinuxLogSource bool = true
param deployNetworking bool = true
param deploySentinel bool = true

@description('Azure Region')
param location string = resourceGroup().location

@description('Start of the Ip Address range for the Vnet. It must end with a .0 as this is using a /24 subnet mask (e.g. 10.0.0.0)') 
@minLength(7)
@maxLength(13)
param vnetAddressIpV4Id string = '10.0.0.0'


@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param _artifactsLocation string = deployment().properties.templateLink.uri

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param _artifactsLocationSasToken string = ''

// Variables
var azureBastionSubnetName = 'AzureBastionSubnet'
var logSourceSubnetName = '${basename}-LogSource-Subnet'
var vmName = '${basename}-LogSource'
var vnetId = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/virtualNetworks/${vnetName}'
var vnetName = '${basename}-vnet'
var workspaceId = '${resourceGroup().id}/providers/Microsoft.OperationalInsights/workspaces/${workspaceName}'
var workspaceName = '${basename}-wksp'

module networkingDeployment 'Network/Networking.bicep' = if (deployNetworking) {
  name: '${datetime}-${basename}-Networking'

  params: {
    basename: basename
    location: location
    logSourceSubnetName: logSourceSubnetName
    vnetAddressIpV4Id: vnetAddressIpV4Id
    vnetName: vnetName
  }
}

module bastionDeployment 'Network/Bastion.bicep' = if (deployBastion) {
  name: '${datetime}-${basename}-Bastion'
  dependsOn: [
    networkingDeployment
  ]
  params: {
    basename: basename
    location: location
    subnetResourceId: '${vnetId}/subnets/${azureBastionSubnetName}'
  }
}
module sentinelDeployment 'Sentinel/Sentinel.bicep' = if (deploySentinel) {
  name: '${datetime}-${basename}-Wksp'
  params: {
    location: location
    workspaceName: workspaceName
  }
}

module DataCollectionRuleDeployment 'Sentinel Data Collection/DataCollectionRules.bicep' = if (deployDataCollectionRule) {
  name: '${datetime}-${basename}-DCR'
  dependsOn: [
    sentinelDeployment
  ]
  params: {
    basename: basename
    location: location
    workspaceResourceId: workspaceId
  }
}

module logSourceDeployment2 'LinuxLogSource/LogSource.bicep' = if (deployLinuxLogSource) {
  name: '${datetime}-${basename}-Log-Source'
  dependsOn: [
    networkingDeployment
  ]
  params: {
    adminPasswordOrKey: adminPasswordOrSSHKey
    adminUsername: adminUsername
    authenticationType: authenticationType
    location: location
    osVersion: 'Ubuntu-2004'
    securityType: 'TrustedLaunch'
    subnetResourceId: '${vnetId}/subnets/${logSourceSubnetName}'
    vmName: vmName
    vmSize: 'Standard_D2s_v3'
    dataCollectionRuleResourceIds: [
      DataCollectionRuleDeployment.outputs.syslogDcrResourceId
    ]
    deployAMA: true
    _artifactsLocation: _artifactsLocation
    _artifactsLocationSasToken: _artifactsLocationSasToken
  }
}
