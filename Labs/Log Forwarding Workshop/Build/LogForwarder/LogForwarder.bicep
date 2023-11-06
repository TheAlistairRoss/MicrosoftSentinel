param location string = resourceGroup().location
param basename string = 'sent-adv-logging-workshop'
param autoscaleMin int = 1
param autoscaleMax int = 10

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
param subnetResourceId string

@allowed([
  'Ubuntu-1804'
  'Ubuntu-2004'
  'Ubuntu-2204'
])
param ubuntuOSVersion string = 'Ubuntu-2004'

@description('The size of the VM')
param vmSize string = 'Standard_F4s_v2'

@description('Optional: Resource Id of the Data Collection Rule or the Data Collection Endpoint to be applied to the scale set')
param dataCollectionRuleOrEndpointResourceId string

@description('The disk type of the managed OS disk')
@allowed([
  'PremiumV2_LRS'
  'Premium_LRS'
  'Premium_ZRS'
  'StandardSSD_LRS'
  'StandardSSD_ZRS'
  'Standard_LRS'
  'UltraSSD_LRS'
])
param vmssOSdiskType string = 'StandardSSD_LRS'

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
var vmssName = '${basename}-vmss'
var storageName = toLower(replace('${basename}diag', '-', ''))
var autoscaleName = '${basename}-autoscale'
var loadbalancerName = '${basename}-lb'
var maxPortRange = ((autoscaleMax <= 9) ? '5000' : '500')
var cloudinit = loadTextContent('./Config/cloudinit-ub.txt')
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

var linuxPasswordConfiguration = {
  disablePasswordAuthentication: false
  provisionVMAgent: true
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
  }
}

resource loadbalancer 'Microsoft.Network/loadBalancers@2019-09-01' = {
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

resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2023-03-01' = {
  name: vmssName
  location: location
  sku: {
    name: vmSize
    tier: 'Standard'
    capacity: autoscaleMin
  }
  properties: {
    singlePlacementGroup: true
    upgradePolicy: {
      mode: 'Rolling'
    }
    virtualMachineProfile: {
      osProfile: {
        computerNamePrefix: basename
        adminUsername: adminUsername
        adminPassword: adminPasswordOrKey
        linuxConfiguration: ((authenticationType == 'password') ? linuxPasswordConfiguration : linuxSSHConfiguration)
        secrets: []
        customData: base64(cloudinit)
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
        imageReference: imageReference[ubuntuOSVersion]
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: '${basename}-nic'
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

resource autoscale 'microsoft.insights/autoscalesettings@2014-04-01' = {
  name: autoscaleName
  location: location
  properties: {
    profiles: [
      {
        name: 'Profile1'
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

resource vmssLinuxAzureMonitorAgent 'Microsoft.Compute/virtualMachineScaleSets/extensions@2023-03-01' = {
  parent: vmss
  name: 'AzureMonitorLinuxAgent'
  properties: {
    autoUpgradeMinorVersion: true
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorLinuxAgent'
    typeHandlerVersion: '1.0'
  }
}

resource AzurePolicyVMMSAMAAssignment 'Microsoft.Authorization/policyAssignments@2023-04-01' = if (!empty(dataCollectionRuleOrEndpointResourceId)) {
  name: '${basename}-LogForwarder-VMSS-DCR'
  properties: {
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/2ea82cdd-f2e8-4500-af75-67a2e084ca74'
    parameters: {
      dcrResourceId: dataCollectionRuleOrEndpointResourceId
    }
  }
}
output b64customData string = base64(cloudinit)
output customData string = cloudinit
output osprofile object = vmss.properties
