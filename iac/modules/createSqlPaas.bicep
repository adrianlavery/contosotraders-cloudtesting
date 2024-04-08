@description('SQL Server Name')
param sqlServerName string

@description('Location')
param location string

@description('Administrator Login Password')
@secure()
param adminPassword string

@description('Administrator Login')
param adminUserName string

@description('Database Name')
param dbName string

@description('Database Capacity')
param dbCapacity int

@description('Database SKU Tier')
param dbSkuTier string

@description('Database SKU Name')
param dbSkuName string

@description('Tags')
param tags object

var dbMaxSizeBytes =  2147483648


// sql azure server with database
module sqlServer 'br/public:avm/res/sql/server:0.2.0' = {
  name: '${uniqueString(deployment().name, location)}-${sqlServerName}'
  params: {
    name: sqlServerName
    administratorLogin: adminUserName
    administratorLoginPassword: adminPassword
    location: location
    tags: tags
    firewallRules: [
      {
        endIpAddress: '0.0.0.0'
        name: 'AllowAllWindowsAzureIps'
        startIpAddress: '0.0.0.0'
      }
    ]
    databases: [
      {
        name: dbName
        capacity: dbCapacity
        skuTier: dbSkuTier
        skuName: dbSkuName
        maxSizeBytes: dbMaxSizeBytes
      }
    ]
  }
}

