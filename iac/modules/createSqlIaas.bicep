
@description('The name of the SQL virtual machine to be created')
param virtualMachineName string = 'sqlVM'

@description('The name of the admin user for the SQL virtual machine')
param adminUserName string = 'azadmin'

@secure()
@description('The password of the admin user for the SQL virtual machine')
param adminPassword string

@description('The availability zone of the SQL virtual machine')
param availabilityZone int = 0

@description('The location of the SQL virtual machine')
param location string = 'eastus'

@description('The size of the SQL virtual machine')
param virtualMachineSize string = 'Standard_D2as_v4' // Need accelerated networking and temp disk

@description('Windows Server and SQL Offer')
@allowed([
  'sql2019-ws2019'
  'sql2017-ws2019'
  'sql2019-ws2022'
  'sql2022-ws2022'
  'SQL2016SP1-WS2016'
  'SQL2016SP2-WS2016'
  'SQL2014SP3-WS2012R2'
  'SQL2014SP2-WS2012R2'
])
param imageOffer string = 'sql2022-ws2022'

@description('SQL Server Sku')
@allowed([
  'standard-gen2'
  'enterprise-gen2'
  'SQLDEV-gen2'
  'web-gen2'
  'enterprisedbengineonly-gen2'
])
param sqlSku string = 'standard-gen2'

@description('The subnet resource id for the SQL virtual machine')
param subnetId string

@description('SQL Server Workload Type')
@allowed([
  'General'
  'OLTP'
  'DW'
])
param storageWorkloadType string = 'General'

@description('Amount of data disks (1TB each) for SQL Data files')
@minValue(1)
@maxValue(8)
param sqlDataDisksCount int = 1

@description('Path for SQL Data files. Please choose drive letter from F to Z, and other drives from A to E are reserved for system')
param dataPath string = 'F:\\SQLData'

@description('Amount of data disks (1TB each) for SQL Log files')
@minValue(1)
@maxValue(8)
param sqlLogDisksCount int = 1

@description('Path for SQL Log files. Please choose drive letter from F to Z and different than the one used for SQL data. Drive letter from A to E are reserved for system')
param logPath string = 'G:\\SQLLog'

var diskConfigurationType = 'NEW'
var dataDisksLuns = range(0, sqlDataDisksCount)
var logDisksLuns = range(sqlDataDisksCount, sqlLogDisksCount)
var dataDisks = {
  createOption: 'Empty'
  caching: 'ReadOnly'
  writeAcceleratorEnabled: false
  storageAccountType: 'Premium_LRS'
  diskSizeGB: 1023
}
var tempDbPath = 'D:\\SQLTemp' 

module virtualMachine 'br/public:avm/res/compute/virtual-machine:0.2.3' = {
    name: '${uniqueString(deployment().name, location)}-${virtualMachineName}'
    params: {
      adminUsername: adminUserName
      adminPassword: adminPassword
      availabilityZone: availabilityZone
      location: location
      name: virtualMachineName
      vmSize: virtualMachineSize
      computerName: split(virtualMachineName, '-')[0]
      osType: 'Windows'
      osDisk: {
        caching: 'ReadWrite'
        diskSizeGB: '128'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      dataDisks: [for j in range(0, length(range(0, (sqlDataDisksCount + sqlLogDisksCount)))): {
        lun: range(0, (sqlDataDisksCount + sqlLogDisksCount))[j]
        createOption: dataDisks.createOption
        caching: ((range(0, (sqlDataDisksCount + sqlLogDisksCount))[j] >= sqlDataDisksCount) ? 'None' : dataDisks.caching)
        writeAcceleratorEnabled: dataDisks.writeAcceleratorEnabled
        diskSizeGB: dataDisks.diskSizeGB
        managedDisk: {
          storageAccountType: dataDisks.storageAccountType
        }
      }]
      imageReference: {
        offer: imageOffer
        publisher: 'MicrosoftSQLServer'
        sku: sqlSku
        version: 'latest'
      }
      nicConfigurations: [
        {
          ipConfigurations: [
            {
              name: 'ipconfig1'
              subnetResourceId: subnetId
            }
          ]
          nicSuffix: 'nic-01'
        }
      ]
    }
}

resource Microsoft_SqlVirtualMachine_sqlVirtualMachines_virtualMachine 'Microsoft.SqlVirtualMachine/sqlVirtualMachines@2022-07-01-preview' = {
  name: virtualMachineName
  dependsOn: [virtualMachine]
  location: location
  properties: {
    virtualMachineResourceId: virtualMachine.outputs.resourceId
    sqlManagement: 'Full'
    sqlServerLicenseType: 'PAYG'
    serverConfigurationsManagementSettings: {
      sqlConnectivityUpdateSettings: {
        connectivityType: 'Public'
        port: 1433
        sqlAuthUpdateUserName: adminUserName
        sqlAuthUpdatePassword: adminPassword
      }
    }
    storageConfigurationSettings: {
      diskConfigurationType: diskConfigurationType
      storageWorkloadType: storageWorkloadType
      sqlDataSettings: {
        luns: dataDisksLuns
        defaultFilePath: dataPath
      }
      sqlLogSettings: {
        luns: logDisksLuns
        defaultFilePath: logPath
      }
      sqlTempDbSettings: {
        defaultFilePath: tempDbPath
      }
    }
  }
}
