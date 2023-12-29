targetScope = 'subscription'

@description('Azure Region')
param location string = 'uksouth'

@minLength(5)
@maxLength(40)
param basename string = 'sentinel-bootcamp'

@description('Start of the Ip Address range for the Vnet. It must end with a .0 as this is using a /24 subnet mask (e.g. 10.0.0.0)') 
@minLength(7)
@maxLength(13)
param vnetAddressIpV4Id string = '10.0.0.0'

@description('If true, Azure Bastion will be deployed. If false, Azure Bastion will not be deployed.')
param deployBastion bool = true

@description('If true, Azure Monitor Private Link Scope and Private DNS Zone will be deployed.')
param deployAMPLS bool = true

@description('If true, Linux Log Source will be deployed.')
param deployLinuxLogSource bool = true

@description('If true, Linux Log Forwarder will be deployed.')
param deployLinuxLogForwarder bool = true


// Linux Log Source Params
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


@allowed([
  'Ubuntu-1804'
  'Ubuntu-2004'
  'Ubuntu-2204'
])
@description('The version of the OS to use for the log source Virtual Machine')
param logSourceOSVersion string = 'Ubuntu-2004'

@description('The size of the log source Virtual Machine')
param logSourceVmSize string = 'Standard_D2s_v3'

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param _artifactsLocation string = deployment().properties.templateLink.uri

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param _artifactsLocationSasToken string = ''
param deploymentTime string =  utcNow()

var resourceGroupName = '${basename}-sentinel-rg'

var vnetName = '${basename}-vnet'
var logSourceSubnetName = 'logSourceSubnet'
var logForwarderSubnetName = 'logForwarderSubnet'
var privateEndpointSubnetName = 'privateEndpointSubnet'

resource SentinelResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
}

module SentinelDeployment 'Sentinel/Sentinel.bicep' = {
  name: 'Sentinel-Deployment-${deploymentTime}'
  scope: SentinelResourceGroup
  params: {
    basename: basename
    location: location
  }
}

module NetworkingDeployment 'Network/Networking.bicep' = {
  name: 'Networking-Deployment-${deploymentTime}'
  scope: SentinelResourceGroup
  params: {
    basename: basename
    location: location
    vnetName: vnetName
    vnetAddressIpV4Id: vnetAddressIpV4Id
    logSourceSubnetName: logSourceSubnetName
    logForwarderSubnetName: logForwarderSubnetName
    privateEndpointSubnetName: privateEndpointSubnetName
  }
}

module BastionDeployment 'Network/Bastion.bicep' = if (deployBastion) {
  name: '${basename}-Bastion-Deployment-${deploymentTime}'
  scope: SentinelResourceGroup
  params: {
    basename: basename
    location: location
    bastionVnetSubnetResourceId: '${NetworkingDeployment.outputs.vNetId}/subnets/AzureBastionSubnet'
  }
}

module AMPLSDeployment 'Network/AMPLS.bicep' = if (deployAMPLS) {
  name: 'AMPLS-Deployment-${deploymentTime}'
  scope: SentinelResourceGroup
  params: {
    basename: basename
    location: location
    virtualNetworkId: NetworkingDeployment.outputs.vNetId
    privateEndpointSubnetName: privateEndpointSubnetName
  }
}

module DataCollectionRuleDeployment 'Sentinel Data Collection/DataCollectionRules.bicep' = {
  name: 'DataCollectionRule-Deployment-${deploymentTime}'
  scope: SentinelResourceGroup
  params: {
    basename: basename
    location: location
    workspaceResourceId: SentinelDeployment.outputs.workspaceId
  }
}

module LinuxLogSourceDeployment 'LinuxLogSource/LogSource.bicep' = if (deployLinuxLogSource) {
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
    ubuntuOSVersion: logSourceOSVersion
    securityType: 'TrustedLaunch'
    vmSize: logSourceVmSize
    subnetResourceId: '${NetworkingDeployment.outputs.vNetId}/subnets/${logSourceSubnetName}'
    dataCollectionRuleResourceId: [
      DataCollectionRuleDeployment.outputs.syslogDcrResourceId
    ]
    _artifactsLocation: _artifactsLocation
    _artifactsLocationSasToken: _artifactsLocationSasToken
  }
}
