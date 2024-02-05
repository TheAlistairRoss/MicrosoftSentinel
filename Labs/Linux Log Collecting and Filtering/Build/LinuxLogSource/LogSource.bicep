// Template for deploying a Linux Virtual Machine with a custom script extension to configure the VM as a Log Source for Microsoft Sentinel
// Parameters
@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

@description('Username for the Virtual Machine.')
param adminUsername string

@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'password'

@description('Location of the resources')
param location string = resourceGroup().location

@allowed([
  'Ubuntu-1804'
  'Ubuntu-2004'
  'Ubuntu-2204'
])
@description('The version of the Ubuntu to use for the Virtual Machine.')
param osVersion string = 'Ubuntu-2004'

@description('Security Type of the Virtual Machine.')
@allowed([
  'Standard'
  'TrustedLaunch'
])
param securityType string = 'TrustedLaunch'

@description('The Resource Id of the subnet to use for the virtual machine')
param subnetResourceId string

@description('The name of your Virtual Machine.')
param vmName string = 'LinuxLogSource'

@description('The size of the VM')
param vmSize string = 'Standard_D2s_v3'

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param _artifactsLocation string = deployment().properties.templateLink.uri

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param _artifactsLocationSasToken string

param deployAMA bool = true

param dataCollectionRuleResourceIds array = []

// Variables
var customScriptExtension = {
  name: 'CustomScript'
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion:  '2.1'
    autoUpgradeMinorVersion: true
    settings: {
      commandToExecute: './config.sh'
      fileUris: scriptFilesUris
    }
  }
}

var imageReference = {
  'Ubuntu-1804': {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '18_04-lts-gen2'
    version: 'latest'
  }
  'Ubuntu-2004': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-focal'
    sku: '20_04-lts-gen2'
    version: 'latest'
  }
  'Ubuntu-2204': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-jammy'
    sku: '22_04-lts-gen2'
    version: 'latest'
  }
}

var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}

var networkInterfaceName = '${vmName}NetInt'

var osDiskType = 'Standard_LRS'

var scriptFiles = [
  'LinuxLogSource/Config/config.sh'
  'LinuxLogSource/Config/rsyslog-50-default.conf'
]
var scriptFilesUris = [for scriptFile in scriptFiles: uri(_artifactsLocation, '${scriptFile}${_artifactsLocationSasToken}')]

var securityProfileJson = {
  uefiSettings: {
    secureBootEnabled: true
    vTpmEnabled: true
  }
  securityType: securityType
}

var trustedLaunchExtension = {
  extensionName: 'GuestAttestation'
  properties: {
    publisher: 'Microsoft.Azure.Security.LinuxAttestation'
    type: 'GuestAttestation'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {
      AttestationConfig: {
        MaaSettings: {
          maaEndpoint: substring('emptystring', 0, 0)
          maaTenantName: 'GuestAttestation'
        }
      }
    }
  }

}

var dcrResourceAssociations = [for dcrResourceId in dataCollectionRuleResourceIds: {
  dataCollectionRuleName: '${guid(dcrResourceId)}-dcrassociation'
  dataCollectionRuleId: dcrResourceId
}]

var azureMonitorAgentLinuxExtension = {
  extensionName: 'AzureMonitorLinuxAgent'
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorLinuxAgent'
    typeHandlerVersion: '1.27'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
}



// Resources
resource networkInterface 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetResourceId
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: vmName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {

    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: imageReference[osVersion]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? null : linuxConfiguration)
    }
    securityProfile: ((securityType == 'TrustedLaunch') ? securityProfileJson : null)
  }
}

resource vmExtension_TrustedLaunch 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = if ((securityType == 'TrustedLaunch') && ((securityProfileJson.uefiSettings.secureBootEnabled == true) && (securityProfileJson.uefiSettings.vTpmEnabled == true))) {
  parent: vm
  name: trustedLaunchExtension.extensionName
  location: location
  properties: trustedLaunchExtension.properties
}

resource vmExtension_AMA 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = if (deployAMA) {
  parent: vm
  dependsOn: [vmExtension_TrustedLaunch]
  name: azureMonitorAgentLinuxExtension.extensionName
  location: location
  properties: azureMonitorAgentLinuxExtension.properties
}

resource vmExtension_CustomScript 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = {
  parent: vm
  name: customScriptExtension.name
  location: location
  dependsOn: [vmExtension_AMA]
  properties: customScriptExtension.properties
}

resource dcrAssociation 'Microsoft.Insights/dataCollectionRuleAssociations@2021-04-01' = [for dcrResourceId in dcrResourceAssociations: {
  scope: vm
  name: dcrResourceId.dataCollectionRuleName
  properties: {
    dataCollectionRuleId: dcrResourceId.dataCollectionRuleId
  }
}
]
