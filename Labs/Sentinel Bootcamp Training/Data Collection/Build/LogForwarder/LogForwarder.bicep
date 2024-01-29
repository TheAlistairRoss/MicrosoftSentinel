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

@description('The maximum number of VMs in the scale set')
param autoscaleMax int = 3

@description('The minimum number of VMs in the scale set')
param autoscaleMin int = 1

@description('Resources Name Prefix')
param basename string = 'sentinel-bootcamp'

@description('The data collection rule resource ids to associate with the VM')
param dataCollectionRuleResourceIds array = []

@description('Location of the resources')
param location string = resourceGroup().location

@allowed([
  'Ubuntu-1804'
  'Ubuntu-2004'
  'Ubuntu-2204'
])
@description('The version of the Ubuntu to use for the Virtual Machine Scale Set')
param OSVersion string = 'Ubuntu-2004'

@description('Security Type of the Virtual Machine.')
@allowed([
  'Standard'
  'TrustedLaunch'
])
param securityType string = 'TrustedLaunch'

@description('The ResourceId of the subnet to use for the virtual machine')
param subnetResourceId string

@description('The name of your Virtual Machine.')
param vmssName string = 'LinuxLogForwarder'

@description('The size of the VM')
param vmssSize string = 'Standard_D2s_v3'

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param _artifactsLocation string = deployment().properties.templateLink.uri

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param _artifactsLocationSasToken string

// Variables

var autoscaleName = '${basename}-autoscale'

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

var linuxPasswordConfiguration = {
  disablePasswordAuthentication: false
  provisionVMAgent: true
}

var linuxSSHConfiguration = {
  disablePasswordAuthentication: true
  provisionVMAgent: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}

var loadbalancerName = '${basename}-lb'

var maxPortRange = ((autoscaleMax <= 9) ? '5000' : '500')

var scriptFiles = [
  'LinuxLogForwarder/Config/config.sh'
  'LinuxLogForwarder/Config/rsyslog-50-default.conf'
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

var vmssNICName = '${vmssName}-nic'

var vmssOSdiskType = 'Standard_LRS'

// Resources

resource existingSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {
  name: '${split(subnetResourceId, '/')[8]}/${split(subnetResourceId, '/')[10]}'
}

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

resource loadbalancer 'Microsoft.Network/loadBalancers@2023-06-01' = {
  name: loadbalancerName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontEnd'
        properties: {
          privateIPAddressVersion: 'IPv4'
          privateIPAllocationMethod: 'Dynamic'
          privateIPAddress: '${substring(existingSubnet.properties.addressPrefix, 0, lastIndexOf(existingSubnet.properties.addressPrefix, '.'))}.100'
          subnet: {
            id: subnetResourceId
          }

        }
      }
    ]
    backendAddressPools: [
      {
        name: 'bepool'
        properties: {}
      }
    ]
    loadBalancingRules: [
      {
        name: 'LBSyslogTCPRule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', loadbalancerName, 'LoadBalancerFrontend')
          }
          frontendPort: 514
          backendPort: 514
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          protocol: 'TCP'
          enableTcpReset: false
          loadDistribution: 'Default'
          disableOutboundSnat: false
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadbalancerName, 'bepool')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', loadbalancerName, 'tcpProbe')
          }
        }
      }
      {
        name: 'LBSyslogUDPRule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', loadbalancerName, 'LoadBalancerFrontend')
          }
          frontendPort: 514
          backendPort: 514
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          protocol: 'Udp'
          enableTcpReset: false
          loadDistribution: 'Default'
          disableOutboundSnat: false
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadbalancerName, 'bepool')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', loadbalancerName, 'tcpProbe')
          }
        }
      }
    ]
    probes: [
      {
        name: 'tcpProbe'
        properties: {
          protocol: 'Tcp'
          port: 514
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
    inboundNatRules: []
    outboundRules: []
    inboundNatPools: [
      {
        name: 'natPool'
        properties: {
          frontendPortRangeStart: 50000
          frontendPortRangeEnd: int('${maxPortRange}${autoscaleMax}')
          backendPort: 22
          protocol: 'Tcp'
          idleTimeoutInMinutes: 5
          enableFloatingIP: false
          enableTcpReset: false
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', loadbalancerName, 'LoadBalancerFrontend')
          }
        }
      }
    ]
  }
}

resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2023-09-01' = {
  name: vmssName
  location: location
  sku: {
    name: vmssSize
    tier: 'Standard'
    capacity: autoscaleMin
  }
  properties: {
    singlePlacementGroup: true
    upgradePolicy: {
      mode: 'Rolling'
      rollingUpgradePolicy: {
          maxBatchInstancePercent: 50
          maxUnhealthyInstancePercent: 50
          maxUnhealthyUpgradedInstancePercent: 50
          pauseTimeBetweenBatches: 'PT30S'
          maxSurge: true   
         }
    }
    virtualMachineProfile: {
      osProfile: {
        computerNamePrefix: basename
        adminUsername: adminUsername
        adminPassword: adminPasswordOrKey
        linuxConfiguration: ((authenticationType == 'password') ? linuxPasswordConfiguration : linuxSSHConfiguration)
        secrets: []
      }
      storageProfile: {
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadWrite'
          managedDisk: {
            storageAccountType: vmssOSdiskType
          }
          diskSizeGB: 32
        }
        imageReference: imageReference[OSVersion]
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: vmssNICName
            properties: {
              primary: true
              enableAcceleratedNetworking: false
              dnsSettings: {
                dnsServers: []
              }
              enableIPForwarding: false
              ipConfigurations: [
                {
                  name: '${basename}-ipConfig'
                  properties: {
                    subnet: {
                      id: subnetResourceId
                    }
                    privateIPAddressVersion: 'IPv4'
                    loadBalancerBackendAddressPools: [
                      {
                        id: '${loadbalancer.id}/backendAddressPools/bepool'
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: '${loadbalancer.id}/inboundNatPools/natPool'
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
        healthProbe: {
          id: '${loadbalancer.id}/probes/tcpProbe'
        }
      }
      diagnosticsProfile: {
        bootDiagnostics: {
          enabled: true
          storageUri: storageAccount.properties.primaryEndpoints.blob
        }
      }
      priority: 'Regular'
    }
    overprovision: true
    doNotRunExtensionsOnOverprovisionedVMs: false
    platformFaultDomainCount: 5
  }
}

resource autoscale 'Microsoft.Insights/autoscalesettings@2022-10-01' = {
  name: autoscaleName
  location: location
  properties: {
    profiles: [
      {
        name: 'CPU Scaling'
        capacity: {
          minimum: '${autoscaleMin}'
          maximum: '${autoscaleMax}'
          default: '${autoscaleMin}'
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricNamespace: ''
              metricResourceUri: vmss.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 75
              dimensions: []
              dividePerInstance: false
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT1M'
            }
          }
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricNamespace: ''
              metricResourceUri: vmss.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 25
              dimensions: []
              dividePerInstance: false
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT1M'
            }
          }
        ]
      }
    ]
    enabled: true
    name: '${basename}-autoscale'
    targetResourceUri: vmss.id
  }
}

resource vmssLinux_AzureMonitorAgent 'Microsoft.Compute/virtualMachineScaleSets/extensions@2023-09-01' = if (!empty((dataCollectionRuleResourceIds))) {
  parent: vmss
  name: 'AzureMonitorLinuxAgent'
  properties: {
    autoUpgradeMinorVersion: true
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorLinuxAgent'
    typeHandlerVersion: '1.0'
  }
}

resource vmssLinux_TrustedLaunch 'Microsoft.Compute/virtualMachineScaleSets/extensions@2023-09-01' = if ((securityType == 'TrustedLaunch') && ((securityProfileJson.uefiSettings.secureBootEnabled == true) && (securityProfileJson.uefiSettings.vTpmEnabled == true))) {
  parent: vmss
  name: trustedLaunchExtension.extensionName
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

resource vmssLinux_CustomScript 'Microsoft.Compute/virtualMachineScaleSets/extensions@2023-09-01' = {
  parent: vmss
  name: customScriptExtension.name
  dependsOn: (!empty((dataCollectionRuleResourceIds))) ? [ vmssLinux_AzureMonitorAgent ] : []
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

// If there are any data collection rules to associate with the VM, create the association
resource dcrAssociation 'Microsoft.Insights/dataCollectionRuleAssociations@2022-06-01' = [for (dcrResourceId, i) in dataCollectionRuleResourceIds: {
  scope: vmss
  name: '${uniqueString(vmss.id, dataCollectionRuleResourceIds[i])}-dcrassociation)}'
  properties: {
    dataCollectionRuleId: dataCollectionRuleResourceIds[i]
  }
}
]
