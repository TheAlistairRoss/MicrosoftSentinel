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

@secure()
param datetime string = utcNow()

param deployAMPLS bool = true
param deployBastion bool = true
param deployDataCollectionRule bool = true
param deployLinuxLogForwarder bool = true
param deployLinuxLogSource bool = true
param deployLogForwarderPolicies bool = false
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



// Resources

resource deployedResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: '${datetime}-${basename}-rg'
  location: location
}




// Modules

module networkingDeployment 'Network/Networking.bicep' = if(deployNetworking){
  name: '${datetime}-${deployment().name}-${basename}-Networking'
  scope: deployedResourceGroup
  params: {
    basename: basename
    location: location
    vnetName: '${basename}-vnet'
    vnetAddressIpV4Id: vnetAddressIpV4Id
  }
}

module bastionDeployment 'Network/Bastion.bicep' = if(deployBastion) {
  name: '${datetime}-${deployment().name}-${basename}-Bastion'
  scope: deployedResourceGroup
  params: {
    basename: basename
    location: location
    subnetResourceId: networkingDeployment.outputs.azureBastionSubnetId
  }
}

module amplsDeployment 'Network/AMPLS.bicep' = if(deployAMPLS){
  name: '${datetime}-${deployment().name}-${basename}-AMPLS'
  scope: deployedResourceGroup
  params: {
    basename: basename
    location: location
    subnetResourceId: networkingDeployment.outputs.privateEndpointSubnetId
  }
}

module sentinelDeployment 'Sentinel/Sentinel.bicep' = if(deploySentinel){
  name: '${datetime}-${deployment().name}-${basename}-Wksp'
  scope: deployedResourceGroup
  params: {
    basename: basename
    location: location
  }
}

module dataCollectionRuleDeployment 'SentinelDataCollection/DataCollectionRules.bicep' = if(deployDataCollectionRule){
  name: '${datetime}-${deployment().name}-${basename}-DCR'
  scope: deployedResourceGroup
  params: {
    basename: basename
    location: location
    workspaceResourceId: sentinelDeployment.outputs.workspaceId
  }
}

module logSourceDeployment 'LinuxLogSource/LogSource.bicep' = if(deployLinuxLogSource){
  name: '${datetime}-${deployment().name}-${basename}-Log-Source'
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

module logForwarderDeployment 'LogForwarder/LogForwarder.bicep' = if(deployLinuxLogForwarder){
  name: '${datetime}-${deployment().name}-${basename}-Log-Forwarder'
  scope: deployedResourceGroup
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
    subnetResourceId: networkingDeployment.outputs.logForwarderSubnetId
    vmssName: '${basename}-Log-Forwarder'
    vmssSize: 'Standard_D2s_v3'
    _artifactsLocation: _artifactsLocation
    _artifactsLocationSasToken: _artifactsLocationSasToken
  }
}

module logForwarderPoliciesDeployment 'PolicyAssignment/PolicyAssignment.bicep' = if(deployLogForwarderPolicies){
  name: '${datetime}-${deployment().name}-${basename}-LF-Policies'
  scope: deployedResourceGroup
  params: {
    policyDefinitionID : '/providers/Microsoft.Authorization/policyDefinitions/050a90d5-7cce-483f-8f6c-0df462036dda'
    policyAssignmentName : '${basename}-Configure Log Forwarder with Data Collection Endpoint'
    policyParameters : {
      effect : 'DeployIfNotExists'
      listOfLinuxImageIdToInclude : []
      dcrResourceId : dataCollectionRuleDeployment.outputs.syslogDcrResourceId // DCR OR DCE Resource Id
      resourceType : 'Microsoft.Insights/dataCollectionEndpoints' //'Microsoft.Insights/dataCollectionRules' OR 'Microsoft.Insights/dataCollectionEndpoints'
    }
  }
}
