targetScope = 'subscription'

// Parameters

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrSSHKey string

param adminUsername string = 'workshopadmin'
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'password'

@description('Resources Name Prefix. This will be used to name most of the resources and the resource group')
param basename string = 'sentinel-bootcamp'

param DeployLogForwarderPolicies bool = false

@description('Azure Region')
param location string = 'uksouth'

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

var LogForwarderBuiltInPoliciesIds = [
  '/providers/Microsoft.Authorization/policyDefinitions/050a90d5-7cce-483f-8f6c-0df462036dda'
]
resource deployedResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
}

var resourceGroupName = '${basename}-sentinel-rg'
var vnetName = '${basename}-vnet'


// Modules

module networkingDeployment 'Network/Networking.bicep' = {
  name: '${basename}-Networking-Deployment'
  scope: deployedResourceGroup
  params: {
    basename: basename
    location: location
    vnetName: vnetName
    vnetAddressIpV4Id: vnetAddressIpV4Id
  }
}

module bastionDeployment 'Network/Bastion.bicep' = {
  name: '${basename}-Bastion-Deployment'
  scope: deployedResourceGroup
  params: {
    basename: basename
    location: location
    subnetResourceId: networkingDeployment.outputs.azureBastionSubnetId
  }
}

module amplsDeployment 'Network/AMPLS.bicep' = {
  name: '${basename}-ampls-Deployment'
  scope: deployedResourceGroup
  params: {
    basename: basename
    location: location
    subnetResourceId: networkingDeployment.outputs.
  }
}

module sentinelDeployment 'Sentinel/Sentinel.bicep' = {
  name: '${basename}-Sentinel-Deployment'
  scope: deployedResourceGroup
  params: {
    basename: basename
    location: location
  }
}

module dataCollectionRuleDeployment 'Sentinel Data Collection/DataCollectionRules.bicep' = {
  name: '${basename}-Data-Collection-Rule-Deployment'
  scope: deployedResourceGroup
  params: {
    basename: basename
    location: location
    workspaceResourceId: sentinelDeployment.outputs.workspaceId
  }
}

module logSourceDeployment 'LinuxLogSource/LogSource.bicep' = {
  name: '${basename}-Log-Source-Deployment'
  scope: deployedResourceGroup
  params: {
    adminPasswordOrKey: adminPasswordOrSSHKey
    adminUsername: adminUsername
    authenticationType: authenticationType
    basename: basename
    location: location
    osVersion  : 'Ubuntu-2004'
    securityType: 'TrustedLaunch'
    subnetResourceId: networkingDeployment.outputs.logSourceSubnetId
    vmName: '${basename}-LogSource'
    vmSize: 'Standard_D2s_v3'
    _artifactsLocation: _artifactsLocation
    _artifactsLocationSasToken: _artifactsLocationSasToken

  }
}

module logForwarderDeployment 'LogForwarder/LogForwarder.bicep' = {
  name: '${basename}-Log-Forwarder-Deployment'
  scope: deployedResourceGroup
  dependsOn: [
    LogSourceDeployment
  ]
  params: {
    basename: basename
    location: location
    logForwarderSubnetName : networkingDeployment.outputs.logForwarderSubnetId
    vmName: '${basename}-Log-Forwarder'
    adminUsername: adminUsername
    authenticationType: authenticationType
    adminPasswordOrKey: adminPasswordOrSSHKey
    ubuntuOSVersion: 'Ubuntu-2004'
    securityType: 'TrustedLaunch'
    vmSize: 'Standard_D2s_v3'
    subnetResourceId: networkingDeployment.outputs.logForwarderSubnetId
    dataCollectionRuleResourceId: [
      dataCollectionRuleDeployment.outputs.syslogDcrResourceId
    ]
    _artifactsLocation: _artifactsLocation
    _artifactsLocationSasToken: _artifactsLocationSasToken
    DeployLogForwarderPolicies: DeployLogForwarderPolicies
    LogForwarderBuiltInPoliciesIds: LogForwarderBuiltInPoliciesIds
  }
}
