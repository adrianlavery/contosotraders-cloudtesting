using 'newCreateResources.bicep'


  param suffix = 'al1'
  param multiRegion = false
  param primaryLocation = 'eastus'
  param secondaryLocation = 'westus'
  param adminPassword = 'Password1234$£!'
  param deployPrivateEndpoints = false
  param deployBackendIaas = true
  param deploymentUserId = '' // We need to pass this as a parameter on the deployment command line using deploymentUserId=$('az ad signed-in-user show --query id -o tsv')
