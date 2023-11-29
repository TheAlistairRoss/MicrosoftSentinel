@description('Location of the resources')
param location string = resourceGroup().location

@description('The name of your Virtual Machine.')
param vmName string = 'LinuxLogSource'

@description('Username for the Virtual Machine.')
param adminUsername string

@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'password'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

@allowed([
  'Ubuntu-1804'
  'Ubuntu-2004'
  'Ubuntu-2204'
])
param ubuntuOSVersion string = 'Ubuntu-2004'

@description('The size of the VM')
param vmSize string = 'Standard_D2s_v3'

@description('Name of the subnet in the virtual network')
param subnetResourceId string

@description('Security Type of the Virtual Machine.')
@allowed([
  'Standard'
  'TrustedLaunch'
])
param securityType string = 'TrustedLaunch'

param deployAMA bool = true

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param _artifactsLocation string = deployment().properties.templateLink.uri

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param _artifactsLocationSasToken string

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

var networkInterfaceName = '${vmName}NetInt'

var osDiskType = 'Standard_LRS'

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

var securityProfileJson = {
  uefiSettings: {
    secureBootEnabled: true
    vTpmEnabled: true
  }
  securityType: securityType
}

var trustedLaunchExtension = {
  extensionName: 'GuestAttestation'
  extensionPublisher: 'Microsoft.Azure.Security.LinuxAttestation'
  extensionVersion: '1.0'
  maaTenantName: 'GuestAttestation'
  maaEndpoint: substring('emptystring', 0, 0)
}

var scriptFiles = [
    '/Labs/Log Collection and Splitting Workshop - Chats and Hacks 2023/Build/LinuxLogSource/Config/cloudinit-ub.sh'
    '/Labs/Log Collection and Splitting Workshop - Chats and Hacks 2023/Build/LinuxLogSource/Config/rsyslog-50-default.conf'
]
var scriptFilesUris = [for scriptFile in scriptFiles: uri(_artifactsLocation, '${scriptFile}${_artifactsLocationSasToken}')]

var customScriptExtension = {
  extensionName: 'CustomScript'
  extensionPublisher: 'Microsoft.Azure.Extensions'
  extensionVersion: '2.1'
  fileUris: scriptFilesUris
  commandToExecute: './cloudinit-ub.sh' 
}

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
      imageReference: imageReference[ubuntuOSVersion]
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

resource vmExtension_AMA 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = if (deployAMA) {
  parent: vm
  name: 'AzureMonitorWindowsAgent'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorWindowsAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
}

resource vmExtension_CustomScript 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = if ((securityType == 'TrustedLaunch') && ((securityProfileJson.uefiSettings.secureBootEnabled == true) && (securityProfileJson.uefiSettings.vTpmEnabled == true))) {
  parent: vm
  name: customScriptExtension.extensionName
  location: location
  dependsOn: deployAMA ? [vmExtension_AMA] : []
  properties: {
    publisher: customScriptExtension.extensionPublisher
    type: customScriptExtension.extensionName
    typeHandlerVersion: customScriptExtension.extensionVersion
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {
      commandToExecute: customScriptExtension.commandToExecute
    }
  }
}
