// Parameters

@description('SSH Key or password for the Virtual Machine.')
@secure()
param adminPasswordOrSSHKey string = 'WorkshopPassword1234'

param adminUsername string = 'workshopadmin'
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'password'

@description('Resources Name Prefix. This will be used to name most of the resources and the resource group')
param basename string = 'sentinel-bootcamp'

@description('Current UTC Datetime in the format YYYYMMDDhhmmss')
param datetime string = utcNow()

param deployAMPLS bool = true
param deployBastion bool = true
param deployDataCollectionRule bool = true
param deployLinuxLogForwarder bool = true
param deployLinuxLogSource bool = true
param deployLogForwarderPolicies bool = true
param deployNetworking bool = true
param deploySentinel bool = true

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

var replaceUriSpaces = replace(_artifactsLocation, ' ', '%20')
var artifactsLocation = '${replaceUriSpaces}${_artifactsLocationSasToken}'

var vnetName = '${basename}-vnet'
var azureBastionSubnetName = 'AzureBastionSubnet'
var logSourceSubnetName = '${basename}-LogSource-Subnet'
var logForwarderSubnetName = '${basename}-LogForwarder-Subnet'
var privateEndpointSubnetName = '${basename}-AMPLS-Subnet'

// Resources

// Modules

module networkingDeployment 'Network/Networking.bicep' = if (deployNetworking) {
  name: '${datetime}-${basename}-Networking'

  params: {
    basename: basename
    location: location
    logForwarderSubnetName: logForwarderSubnetName
    logSourceSubnetName: logSourceSubnetName
    privateEndpointSubnetName: privateEndpointSubnetName
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
    subnetResourceId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, azureBastionSubnetName)
  }
}

module amplsDeployment 'Network/AMPLS.bicep' = if (deployAMPLS) {
  name: '${datetime}-${basename}-AMPLS'
  dependsOn: [
    networkingDeployment
  ]

  params: {
    basename: basename
    location: location
    subnetResourceId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, privateEndpointSubnetName)
  }
}

module sentinelDeployment 'Sentinel/Sentinel.bicep' = if (deploySentinel) {
  name: '${datetime}-${basename}-Wksp'
  params: {
    basename: basename
    location: location
  }
}

module dataCollectionRuleDeployment 'SentinelDataCollection/DataCollectionRules.bicep' = if (deployDataCollectionRule) {
  name: '${datetime}-${basename}-DCR'
  params: {
    basename: basename
    location: location
    workspaceResourceId: sentinelDeployment.outputs.workspaceId
  }
}

module logSourceDeployment 'LinuxLogSource/LogSource.bicep' = if (deployLinuxLogSource) {
  name: '${datetime}-${basename}-Log-Source'
  dependsOn: [
    networkingDeployment
  ]

  params: {
    adminPasswordOrKey: adminPasswordOrSSHKey
    adminUsername: adminUsername
    authenticationType: authenticationType
    basename: basename
    location: location
    osVersion: 'Ubuntu-2004'
    securityType: 'TrustedLaunch'
    subnetResourceId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, logSourceSubnetName)
    vmName: '${basename}-LogSource'
    vmSize: 'Standard_D2s_v3'
    _artifactsLocation: artifactsLocation
    _artifactsLocationSasToken: _artifactsLocationSasToken

  }
}

module logForwarderDeployment 'LogForwarder/LogForwarder.bicep' = if (deployLinuxLogForwarder) {
  name: '${datetime}-${basename}-Log-Forwarder'
  dependsOn: [
    networkingDeployment
  ]

  params: {
    adminPasswordOrKey: adminPasswordOrSSHKey
    adminUsername: adminUsername
    authenticationType: authenticationType
    autoscaleMin: 1
    autoscaleMax: 3
    basename: basename
    dataCollectionRuleResourceIds: [
      dataCollectionRuleDeployment.outputs.syslogDcrResourceId
    ]
    location: location
    OSVersion: 'Ubuntu-2004'
    securityType: 'TrustedLaunch'
    subnetResourceId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, logForwarderSubnetName)
    vmssName: '${basename}-Log-Forwarder'
    vmssSize: 'Standard_D2s_v3'
    _artifactsLocation: artifactsLocation
    _artifactsLocationSasToken: _artifactsLocationSasToken
  }
}

resource logForwarderPolicyAssignment 'Microsoft.Authorization/policyAssignments@2023-04-01' = {
  name: '${datetime}-${basename}-LF-Policies'
  properties: {
    description: 'Assign the Log Forwarder Scale set to data collection rules'
    displayName: 'Assign the Log Forwarder Scale set to data collection rules'
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/050a90d5-7cce-483f-8f6c-0df462036dda'
    parameters: {
      effect: {value: 'DeployIfNotExists'}

      listOfLinuxImageIdToInclude: {value: []}
      dcrResourceId: {value: dataCollectionRuleDeployment.outputs.syslogDcrResourceId} // DCR OR DCE Resource Id
      resourceType: {value: 'Microsoft.Insights/dataCollectionEndpoints'} //'Microsoft.Insights/dataCollectionRules' OR 'Microsoft.Insights/dataCollectionEndpoints'
    }
  }
}
