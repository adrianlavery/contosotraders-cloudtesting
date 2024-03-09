//
// Creates number of VMs in count var (3) 
// Adds them to the poolSubnetID subnet from vNet_subnets module 
// Installs IIS on the severs
//
// With intneral loadbalancer infront of the machines 
//

param location string 
//param vNet string

// param azCopyScript string

//param backendPoolID string
param exsistingSubnetName string
param exsistingVirtualNetworkName string 
param exsitingVNetResourceGroup string 


@description('The admin user name of the VM')
param adminUsername string

@description('The admin password of the VM')
@secure()
param adminPassword string

//Variables

var count = 3
var vmName = 'vmiis'
var vmNicName = '${vmName}nic' 

var vmSize = 'Standard_D8s_v3'
var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var imageSku = '2019-Datacenter'

var loadBalancerName = 'iisInternalLb'

var subnetRef = resourceId(exsitingVNetResourceGroup, 'Microsoft.Network/virtualNetWorks/subnets', exsistingVirtualNetworkName, exsistingSubnetName)

//
resource publicIP 'Microsoft.Network/publicIPAddresses@2021-08-01' = {
  name: 'lbpublicIPname' 
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    }
  }

//Internal Load Balancer Setup 
resource loadBalancer 'Microsoft.Network/loadBalancers@2021-05-01' = {
  name: loadBalancerName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [ 
      {
        name: 'LoadBalancerFrontend'
        properties: {
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'BackendPool1'
      }
    ]
    loadBalancingRules: [
      {
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', loadBalancerName, 'LoadBalancerFrontend')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, 'BackendPool1')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', loadBalancerName, 'lbprobe')
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          idleTimeoutInMinutes: 15
        }
        name: 'lbrule'
      }
    ]
    probes: [
      {
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 15
          numberOfProbes: 2
        }
        name: 'lbprobe'
      }
    ]
  }
  //dependsOn: [
    //publicIP
  //]
}


@batchSize(1)
resource vmNic 'Microsoft.Network/networkInterfaces@2021-08-01' = [for i in range(0,count): {
  name: '${vmNicName}-${i}'
  location: location
  properties: {
    ipConfigurations: [
       {
        name: '${vmNicName}-${i}IPconfig'
         properties: {
          privateIPAllocationMethod: 'Dynamic'
          privateIPAddressVersion: 'IPv4'
          subnet: {
             id: subnetRef
          }
          //I feel this should be changed out into an if statement to make it more resusable
          loadBalancerBackendAddressPools: [
             {
               id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, 'BackendPool1')
             }
          ]
        }
       }
    ]
  }
  dependsOn: [
     loadBalancer
  ]
}]


@batchSize(1)
resource virtualMachine 'Microsoft.Compute/virtualMachines@2022-03-01' = [for i in range(0,count): {
  name: '${vmName}-${i}'
  location: location 
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    } 
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSku
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
       }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${vmNicName}-${i}')
        }
      ]
    }
    osProfile: {
      computerName: vmName
      adminPassword: adminPassword
      adminUsername: adminUsername
    }
  }
  dependsOn: [
    vmNic
  ]
}]

@batchSize(1)
resource InstallWebServer 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = [for i in range(0, count): {
  name: '${vmName}-${i}/InstallWebServer'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.7'
    autoUpgradeMinorVersion: true
    settings: {
      commandToExecute: 'powershell.exe Install-WindowsFeature -name Web-Server -IncludeManagementTools && powershell.exe remove-item \'C:\\inetpub\\wwwroot\\iisstart.htm\' && powershell.exe Add-Content -Path \'C:\\inetpub\\wwwroot\\iisstart.htm\' -Value $(\'Hello World from \' + $env:computername)'
    }
  }
  dependsOn: [
    virtualMachine
    vmNic
  ]
}]

// @batchSize(1)
// resource InstallAzCopy 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = [for i in range(0, count): {
//   name: '${vmName}-${i}/InstallAzCopy'
//   location: location
//   properties: {
//     publisher: 'Microsoft.Compute'
//     type: 'CustomScriptExtension'
//     typeHandlerVersion: '1.7'
//     autoUpgradeMinorVersion: true
//     settings: {
//       commandToExecute: 'powershell.exe ${azCopyScript}'
//     }
//   }
//   dependsOn: [
//     virtualMachine
//     vmNic
//   ]
// }]

output lbIPAddress string = publicIP.properties.ipAddress

