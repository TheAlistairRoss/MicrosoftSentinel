@description('Azure Region')
param location string = 'uksouth'

@minLength(5)
@maxLength(40)
param basename string = 'sent-adv-logging-workshop'

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param _artifactsLocation string = deployment().properties.templateLink.uri

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param _artifactsLocationSasToken string = ''


// Networking 

@description('Name for Log Source and Log Forwarder Vnets')
param vnetName string = '${basename}-logging-vnet'

param deployBastion bool = false

var vnetConfig = {
  addressSpacePrefix: '10.0.0.0/24'
  subnets: [
    {
      name: 'AzureBastionSubnet'
      addressPrefix: '10.0.0.0/25'
    }
    {
      name: 'logSource'
      addressPrefix: '10.0.0.128/25'
    }
  ]
}

var bastionHostName = '${basename}-bastion'
var bastionSubnetNSGName = '${bastionHostName}-nsg'
var bastionPublicIpAddressName = '${bastionHostName}-pip'


resource bastionSubnetNSG 'Microsoft.Network/networkSecurityGroups@2022-07-01' =  if (deployBastion) {
  name: bastionSubnetNSGName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowHttpsInBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowGatewayManagerInBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'GatewayManager'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowLoadBalancerInBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowBastionHostCommunicationInBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowSshRdpOutBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRanges: [
            '22'
            '3389'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowAzureCloudCommunicationOutBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '443'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 110
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowBastionHostCommunicationOutBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 120
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowGetSessionInformationOutBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          destinationPortRanges: [
            '80'
            '443'
          ]
          access: 'Allow'
          priority: 130
          direction: 'Outbound'
        }
      }
      {
        name: 'DenyAllOutBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  dependsOn: (deployBastion) ? [
    bastionSubnetNSG
  ]: []
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetConfig.addressSpacePrefix
      ]
    }
  }
}

resource vnetBastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  name: vnetConfig.subnets[0].name
  properties: {
    networkSecurityGroup: (deployBastion) ? {
      id: reference('bastionSubnetNSG').id
    } :{}
    addressPrefix: vnetConfig.subnets[0].addressPrefix
  }
  parent: vnet
}

resource vnetLogSourceSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' =  {
  name: vnetConfig.subnets[1].name
  properties: {
    addressPrefix: vnetConfig.subnets[1].addressPrefix
  }
  parent: vnet
}


resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@2022-07-01' =  if( deployBastion) {
  name: bastionPublicIpAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2022-07-01' = if (deployBastion) {
  name: bastionHostName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: vnetBastionSubnet.id 
          }
          publicIPAddress: {
            id: bastionPublicIp.id
          }
        }
      }
    ]
  }
}



// Sentinel
var workspaceName = '${basename}-wksp'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
name: workspaceName
location: location
}

resource sentinel 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'SecurityInsights(${workspaceName})'
  location: location
  plan: {
    name: 'SecurityInsights(${workspaceName})'
    promotionCode: ''
    product: 'OMSGallery/SecurityInsights'
    publisher: 'Microsoft'
  }
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
  }
}

// Data Collection Rule

resource cefDataCollectionRule 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: '${basename}-cef-dcr'
  location: location
  kind: 'Linux'
  properties: {
    dataSources: {
      syslog: [
        {
          streams: [
            'Microsoft-CommonSecurityLog'
          ]
          facilityNames: [
            'auth'
            'authpriv'
            'local0'
          ]
          logLevels: [
            'Info'
            'Notice'
            'Warning'
            'Error'
            'Critical'
            'Alert'
            'Emergency'
          ]
          name: 'sysLogsDataSource'
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: logAnalyticsWorkspace.id
          name: 'DataCollectionEvent'
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-CommonSecurityLog'
        ]
        destinations: [
          'DataCollectionEvent'
        ]
      }
    ]
  }
}

// Log Source
@description('The name of your Virtual Machine.')
param vmName string = 'LinuxLogSource'



@allowed([
  'Ubuntu-1804'
  'Ubuntu-2004'
  'Ubuntu-2204'
])
param ubuntuOSVersion string = 'Ubuntu-2004'

@description('The size of the VM')
param vmSize string = 'Standard_D2s_v3'

@description('Security Type of the Virtual Machine.')
@allowed([
  'Standard'
  'TrustedLaunch'
])
param securityType string = 'TrustedLaunch'

param adminUsername string = 'workshopadmin'

@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'password'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

param deployVMPublicIP bool = true

param deployAMA bool = true

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

var vmPublicIpAddressName = '${vmName}}-pip'


resource vmPublicIp 'Microsoft.Network/publicIPAddresses@2022-07-01' =  if(deployVMPublicIP) {
  name: vmPublicIpAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
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
            id: vnetLogSourceSubnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: (deployVMPublicIP) ? {
            id: reference('vmPublicIp').id
          } : {}
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
  name: 'AzureMonitorLinuxAgent'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorLinuxAgent'
    typeHandlerVersion: '1.27'
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
    settings: {
      commandToExecute: customScriptExtension.commandToExecute
    }
  }
}
