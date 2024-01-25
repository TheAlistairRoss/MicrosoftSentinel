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

@description('Resources Name Prefix')
param basename string = 'sentinel-bootcamp'

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

// Variables

var customScriptExtension = {
  name: 'CustomScript'
  publisher: 'Microsoft.Azure.Extensions'
  typeHandlerVersion: '2.1'
  fileUris: scriptFilesUris
  commandToExecute: './config.sh'
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

var storageAccountName = toLower(replace('${basename}diag', '-', ''))

var trustedLaunchExtension = {
  extensionName: 'GuestAttestation'
  extensionPublisher: 'Microsoft.Azure.Security.LinuxAttestation'
  extensionVersion: '1.0'
  maaTenantName: 'GuestAttestation'
  maaEndpoint: substring('emptystring', 0, 0)
}

var vmNetworkInterfaceName = '${vmName}NetInt'

// Resources
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
  }
}

resource vmNetworkInterface 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: vmNetworkInterfaceName
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
          id: vmNetworkInterface.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageAccount.properties.primaryEndpoints.blob
      }
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
  properties: {
    publisher: trustedLaunchExtension.extensionPublisher
    type: trustedLaunchExtension.extensionName
    typeHandlerVersion: trustedLaunchExtension.extensionVersion
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {
      AttestationConfig: {
        MaaSettings: {
          maaEndpoint: trustedLaunchExtension.maaEndpoint
          maaTenantName: trustedLaunchExtension.maaTenantName
        }
      }
    }
  }
}

resource vmExtension_CustomScript 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = {
  parent: vm
  name: customScriptExtension.name
  location: location
  properties: {
    publisher: customScriptExtension.publisher
    type: customScriptExtension.name
    typeHandlerVersion: customScriptExtension.typeHandlerVersion
    autoUpgradeMinorVersion: true
    settings: {
      commandToExecute: customScriptExtension.commandToExecute
      fileUris: customScriptExtension.fileUris
    }
  }
}

