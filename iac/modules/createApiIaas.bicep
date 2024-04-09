
@description('The prefix of the virtual machines to be created')
param virtualMachineName string = 'apiVM'

@description('The name of the admin user for the virtual machines')
param adminUserName string = 'azadmin'

@secure()
@description('The password of the admin user for the virtual machines')
param adminPassword string 

@description('The location of the virtual machines')
param location string = 'eastus'

@description('The size of the SQL virtual machine')
param virtualMachineSize string = 'Standard_B2as_v2'

@description('The image offer of the virtual machines')
param imageOffer string = '0001-com-ubuntu-server-jammy'

@description('The image publisher of the virtual machines')
param imagePublisher string = 'Canonical'

@description('The image sku of the virtual machines')
param imageSku string = '22_04-lts-gen2'

@description('The image version of the virtual machines')
param imageVersion string = 'latest'

@description('The number of instances in the scale set')
param instanceCount int = 3

@description('The availability zones of the virtual machines')
param availabilityZones array = ['0']

@description('The subnet id of the virtual machines')
param subnetId string

@description('The managed identity resource id')
param managedIdentityResourceId string

@description('The ACR object')
param acr object

@description('The acr password')
param acrPassword string

@description('The Repository name')
param acrRepository string

@description('The KeyVault URI')
param keyVaultUri string

@description('Tags')
param tags object = {environment: 'test'}


module virtualmachinescaleset 'br/public:avm/res/compute/virtual-machine-scale-set:0.1.1' = {
  name: '${uniqueString(deployment().name, location)}-${virtualMachineName}'
  params: {
    adminUsername: adminUserName
    adminPassword: adminPassword
    name: virtualMachineName
    location: location
    skuName: virtualMachineSize
    availabilityZones: availabilityZones
    imageReference: {
      offer: imageOffer
      publisher: imagePublisher
      sku: imageSku
      version:  imageVersion
    }
    osDisk: {
      createOption: 'FromImage'
      diskSizeGB: 128
      managedDisk: {
        storageAccountType: 'Standard_LRS'
      }
    }
    osType: 'Linux'
    nicConfigurations: [
      {
        ipconfigurations: [
          {
            name: 'ipconfig1'
            properties: {
              subnet: {
                id: subnetId
              }
            }
          }
        ]
        nicSuffix: '-nic01'
      }
    ]
    extensionCustomScriptConfig: {
      enabled: true
      commandToExecute: 'deployAPI.sh ${acr.ouputs.name} ${acrPassword} ${acr.ouputs.loginServer} ${acrRepository} ${keyVaultUri} ${managedIdentityResourceId}'
      fileData: [
        {
          uri: 'https://github.com/adrianlavery/contosotraders-cloudtesting/blob/main/iac/scripts/deployAPI.sh'
        }
      ]
      
    }
    skuCapacity: instanceCount
    vmNamePrefix: virtualMachineName
    managedIdentities: {
      userAssignedResourceIds: [
        managedIdentityResourceId
      ]
    }
    tags: tags
  }
}


