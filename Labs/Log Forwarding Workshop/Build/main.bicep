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

@secure()
param adminPassword string
param logForwarderAutoscaleMin int = 1
param logForwarderAutoscaleMax int = 2

param deployAMPLS bool = true
param deployDataCollectionRule bool = true
param configureLogSource bool = true
param deployLogSplittingDataCollectionRule bool = true

var logSourceResourceGroupName = '${basename}-log-source-rg'
var logForwarderResourceGroupName = '${basename}-log-forwarder-rg'
var NetworkingResourceGroupName = '${basename}-networking-rg'
var SentinelResourceGroupName = '${basename}-sentinel-rg'

resource logSourceResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: logSourceResourceGroupName
  location: location
}

resource logForwarderResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: logForwarderResourceGroupName
  location: location
}

resource NetworkingResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: NetworkingResourceGroupName
  location: location
}

resource SentinelResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: SentinelResourceGroupName
  location: location
}

module NetworkingDeployment 'Network/Networking.bicep' = {
  name: '${basename}-Networking-Deployment'
  scope: NetworkingResourceGroup
  params: {
    basename: basename
    location:location
    amplsIngestionAccessMode: 'Open'
    amplsQueryAccessMode: 'Open'
    vnet1Name: '${basename}-logging-vnet'
    vnet2Name: '${basename}-sentinel-vnet'
  }
}

module SentinelDeployment 'Sentinel/Sentinel.bicep' = {
  name: '${basename}-Sentinel-Deployment'
  scope: SentinelResourceGroup
  params: {
    basename: basename
    location:location
  }
}

module DataCollectionRuleDeployment 'Sentinel Data Collection/DataCollectionRules.bicep' = {
  name: '${basename}-Data-Collection-Rule-Deployment'
  scope: SentinelResourceGroup
  params: {
    basename: basename
    location: location
    dataCollectionEndpointId: SentinelDeployment.outputs.dataCollectionEndpointId
    workspaceResourceId: SentinelDeployment.outputs.workspaceId
  }
}

module AMPLSConnectionDeployment 'Sentinel Data Collection/AMPLSConnection.bicep' = {
  name: '${basename}-AMPLS-Connection-Deployment'
  scope: NetworkingResourceGroup
  params: {
    amplsResourceId: NetworkingDeployment.outputs.AMPLSResourceId
    amplsScopedResourceIds: [
      SentinelDeployment.outputs.workspaceId
      SentinelDeployment.outputs.dataCollectionEndpointId
    ]
  }

}

module LogForwarderDeployment 'LogForwarder/LogForwarder.bicep' = {
  name: '${basename}-Log-Forwarder-Deployment'
  scope: logForwarderResourceGroup
  dependsOn: [
    NetworkingDeployment
  ]
  params: {
    basename: basename
    location: location
    subnetResourceId:  NetworkingDeployment.outputs.LogForwarderSubnetResourceId
    adminUsername: adminUsername
    authenticationType: authenticationType
    adminPasswordOrKey: adminPassword
    autoscaleMin: logForwarderAutoscaleMin
    autoscaleMax: logForwarderAutoscaleMax
    dataCollectionRuleOrEndpointResourceId : SentinelDeployment.outputs.dataCollectionEndpointId
  }
}

module LogSourceDeployment 'LogSource/LogSource.bicep' = {
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
  securityType:'TrustedLaunch'
  vmSize: 'Standard_D2s_v3'
  subnetResourceId: NetworkingDeployment.outputs.LogSourceSubnetResourceId
}
}

