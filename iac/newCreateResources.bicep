//This is a new file to clean up the createResources.bicep. Once complete, we can remove the createResources.bicep file.

// common
targetScope = 'resourceGroup'


// parameters
////////////////////////////////////////////////////////////////////////////////

// common
@minLength(3)
@maxLength(6)
@description('A unique environment suffix (max 6 characters, alphanumeric only).')
param suffix string

@description('The object ID of the user that will run the deployment')
param deploymentUserId string

@description('The prefix to use for all resources, hyphenated.')
param prefix string = 'contosotraders'

@description('The prefix to use for all resources, hyphenated.')
param prefixHyphenated string = 'contoso-traders'

@description('Whether to deploy resources to a single region or multiple regions.')
param multiRegion bool = false

@description('The primary location of all resources.')
param primaryLocation string = 'eastus'

@description('The secondary location of all resources. If not used then resources will only be deployed to a single region.')
param secondaryLocation string = 'westus'

@secure()
@description('Admin password to be used for all required resources')
param adminPassword string

@description('Whether to deploy private endpoints for the PAAS resources.')
param deployPrivateEndpoints bool = false

@description('Whether to deploy IAAS resources for the frontend.')
param deployFrontendIaas bool = false

@description('Whether to deploy IAAS resources for the middle tier.')
param deployMiddleTierIaas bool = false

@description('Whether to deploy IAAS resources for the backend.')
param deployBackendIaas bool = false

@description('VNet address space for the primary location')
param primaryVnetAddressSpace string = '10.1.0.0/16'

@description('VNet address space for the secondary location')
param secondaryVnetAddressSpace string = '10.2.0.0/16'



// variables
////////////////////////////////////////////////////////////////////////////////


// regions
var regions = multiRegion ? [primaryLocation, secondaryLocation] : [primaryLocation]

// key vault
var kvName = 'kv${suffix}'

// tags
var resourceTags = {
  Product: prefixHyphenated
  Environment: suffix
}


// subnet ids

var primaryBackendSubnetId = vnet[0].outputs.subnetResourceIds[3]
var secondaryBackendSubnetId = multiRegion ? vnet[1].outputs.subnetResourceIds[3] : ''

// frontend

// middle tier

// backend
var productsDbServerName = '${prefix}-products${suffix}'
var productsDbName = 'productsdb'
var profilesDbServerName = '${prefix}-profiles${suffix}'
var profilesDbName = 'profilesdb'

// resources
////////////////////////////////////////////////////////////////////////////////



// Common Resources
////////////////////////////////////////////////////////////////////////////////

// Create a VNET in each region if either private endpoints are required or IAAS is required
module vnet 'br/public:avm/res/network/virtual-network:0.1.5' = [for region in regions: if (deployPrivateEndpoints || deployFrontendIaas || deployMiddleTierIaas || deployBackendIaas) { 
  name: 'vnet-${region}-deployment'
  params: {
    name: '${prefixHyphenated}-vnet${suffix}-${region}'
    location: region
    addressPrefixes: [
      region == primaryLocation ? primaryVnetAddressSpace : secondaryVnetAddressSpace
    ]
    subnets: [
      {
        name: 'AzureBastionSubnet'
        addressPrefix: region == primaryLocation ? '${substring(primaryVnetAddressSpace, 0, 4)}.1.0/24' : '${substring(secondaryVnetAddressSpace, 0, 4)}.1.0/24'
      }
      {
        name: 'FrontEndSubnet'
        addressPrefix: region == primaryLocation ? '${substring(primaryVnetAddressSpace, 0, 4)}.2.0/24' : '${substring(secondaryVnetAddressSpace, 0, 4)}.2.0/24'
      }
      {
        name: 'MiddleTierSubnet'
        addressPrefix: region == primaryLocation ? '${substring(primaryVnetAddressSpace, 0, 4)}.3.0/24' : '${substring(secondaryVnetAddressSpace, 0, 4)}.3.0/24'
      }
      {
        name: 'BackendSubnet'
        addressPrefix: region == primaryLocation ? '${substring(primaryVnetAddressSpace, 0, 4)}.4.0/24' : '${substring(secondaryVnetAddressSpace, 0, 4)}.4.0/24'
      }
    ]
  }
}]

// create a keyvault per region to store secrets
module keyvault 'br/public:avm/res/key-vault/vault:0.4.0' = [for region in regions:  {
  name: 'kv-${region}-deployment'
  dependsOn: deployPrivateEndpoints ? vnet : []
  params: {
    name: '${kvName}-${region}'
    location: region
    enableRbacAuthorization: true
    enableVaultForTemplateDeployment: true
    publicNetworkAccess: 'Enabled' // Need this for local testing to get admin password from keyvault
    privateEndpoints: deployPrivateEndpoints ? [
      {
        service: 'vault'
        subnetResourceId: region == primaryLocation ? primaryBackendSubnetId : secondaryBackendSubnetId
        location: region
      }
    ] : []
    secrets: {
      secureList: [
        {
          attributesExp: 1702648632
          attributesNbf: 10000
          name: 'adminPassword'
          value: adminPassword
        }
      ]
    }
    roleAssignments: [
      {
        principalId: deploymentUserId
        roleDefinitionIdOrName: 'Key Vault Secrets Officer'
      }
    ]
    sku: 'standard'
    tags: resourceTags
  }
}]




// Frontend Resources
////////////////////////////////////////////////////////////////////////////////





// Middle Tier Resources
////////////////////////////////////////////////////////////////////////////////





// Backend Resources
////////////////////////////////////////////////////////////////////////////////

// Create IAAS SQL servers

module productsSqlServer 'modules/createSqlIaas.bicep' = [for region in regions: if (deployBackendIaas) {
  name : 'productsvm-${region}-deployment'
  dependsOn: vnet
  params: {
    adminPassword: adminPassword
    subnetId: region == primaryLocation ? primaryBackendSubnetId : secondaryBackendSubnetId
    virtualMachineName: 'productsvm-${region}'
    location: region
  } 
}]

module profilesSqlServer 'modules/createSqlIaas.bicep' = [for region in regions: if (deployBackendIaas) {
  name : 'profilesvm-${region}-deployment'
  dependsOn: vnet
  params: {
    adminPassword: adminPassword
    subnetId: region == primaryLocation ? primaryBackendSubnetId : secondaryBackendSubnetId
    virtualMachineName: 'profilesvm-${region}'
    location: region
  } 
}]

// Create PAAS SQL

module productsSql 'modules/createSqlPaas.bicep' = [for region in regions: if (!deployBackendIaas) {
  name : 'products-sql-${region}-deployment'
  params: {
    location: region
    adminUserName: 'localadmin'
    adminPassword: adminPassword
    sqlServerName: '${productsDbServerName}-${region}'
    dbSkuName: 'Basic'
    dbSkuTier: 'Basic'
    dbCapacity: 5
    dbName: productsDbName
    tags: resourceTags
  }
}]

module profilesSql 'modules/createSqlPaas.bicep' = [for region in regions: if (!deployBackendIaas) {
  name : 'profiles-sql-${region}-deployment'
  params: {
    location: region
    adminUserName: 'localadmin'
    adminPassword: adminPassword
    sqlServerName: '${profilesDbServerName}-${region}'
    dbSkuName: 'Basic'
    dbSkuTier: 'Basic'
    dbCapacity: 5
    dbName: profilesDbName
    tags: resourceTags
  }
}]
