param frontdoorname string = 'MyFrontDoor'
param productapicname string
param cartapicname string
param imagescname string
param webstorecname string
param resourceTags object

resource profiles_MyFrontDoor_name_resource 'Microsoft.Cdn/profiles@2022-11-01-preview' = {
  name: frontdoorname
  location: 'Global'
  tags: resourceTags
  sku: {
    name: 'Standard_AzureFrontDoor'
  }
  // Remove the assignment of the value 'frontdoor' to the read-only property "kind"
  // kind: 'frontdoor'
  properties: {
    originResponseTimeoutSeconds: 30
    // Remove the assignment of an empty object to the read-only property "extendedProperties"
    // extendedProperties: {}
  }  
}

resource profiles_MyFrontDoor_name_web 'Microsoft.Cdn/profiles/afdendpoints@2022-11-01-preview' = {
  parent: profiles_MyFrontDoor_name_resource
  name: 'web'
  location: 'Global'
  tags: resourceTags
  properties: {
    enabledState: 'Enabled'
  }
}

resource profiles_MyFrontDoor_name_apis 'Microsoft.Cdn/profiles/afdendpoints@2022-11-01-preview' = {
  parent: profiles_MyFrontDoor_name_resource
  name: 'apis'
  location: 'Global'
  tags: resourceTags
  properties: {
    enabledState: 'Enabled'
  }
}

resource profiles_MyFrontDoor_name_images 'Microsoft.Cdn/profiles/afdendpoints@2022-11-01-preview' = {
  parent: profiles_MyFrontDoor_name_resource
  name: 'images'
  location: 'Global'
  tags: resourceTags
  properties: {
    enabledState: 'Enabled'
  }
}

resource profiles_MyFrontDoor_name_cartapiorigingroup 'Microsoft.Cdn/profiles/origingroups@2022-11-01-preview' = {
  parent: profiles_MyFrontDoor_name_resource
  name: 'cartapiorigingroup'
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: 50
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Http'
      probeIntervalInSeconds: 100
    }
    sessionAffinityState: 'Disabled'
  }
}

resource profiles_MyFrontDoor_name_imagesgroup 'Microsoft.Cdn/profiles/origingroups@2022-11-01-preview' = {
  parent: profiles_MyFrontDoor_name_resource
  name: 'imagesgroup'
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: 50
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Http'
      probeIntervalInSeconds: 100
    }
    sessionAffinityState: 'Disabled'
  }
}

resource profiles_MyFrontDoor_name_MyOriginGroup 'Microsoft.Cdn/profiles/origingroups@2022-11-01-preview' = {
  parent: profiles_MyFrontDoor_name_resource
  name: 'WebOriginGroup'
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: 0
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Https'
      probeIntervalInSeconds: 100
    }
    sessionAffinityState: 'Disabled'
  }
}

resource profiles_MyFrontDoor_name_prodapiorigingroup 'Microsoft.Cdn/profiles/origingroups@2022-11-01-preview' = {
  parent: profiles_MyFrontDoor_name_resource
  name: 'prodApiOriginGroup'
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: 50
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Http'
      probeIntervalInSeconds: 100
    }
    sessionAffinityState: 'Disabled'
  }
}

resource profiles_MyFrontDoor_name_cartapiorigingroup_cartapiorigin 'Microsoft.Cdn/profiles/origingroups/origins@2022-11-01-preview' = {
  parent: profiles_MyFrontDoor_name_cartapiorigingroup
  name: 'cartApiOrigin'
  properties: {
    hostName: cartapicname
    httpPort: 80
    httpsPort: 443
    originHostHeader: cartapicname
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
    enforceCertificateNameCheck: false
  }
}

resource profiles_MyFrontDoor_name_imagesgroup_imagesorigin 'Microsoft.Cdn/profiles/origingroups/origins@2022-11-01-preview' = {
  parent: profiles_MyFrontDoor_name_imagesgroup
  name: 'imagesOrigin'
  properties: {
    hostName: imagescname
    httpPort: 80
    httpsPort: 443
    originHostHeader: imagescname
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
    enforceCertificateNameCheck: false
  }
}

resource profiles_MyFrontDoor_name_prodapiorigingroup_prodapiorigin 'Microsoft.Cdn/profiles/origingroups/origins@2022-11-01-preview' = {
  parent: profiles_MyFrontDoor_name_prodapiorigingroup
  name: 'prodApiOrigin'
  properties: {
    hostName: productapicname
    httpPort: 80
    httpsPort: 443
    originHostHeader: productapicname
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
    enforceCertificateNameCheck: false
  }
}

resource profiles_MyFrontDoor_name_MyOriginGroup_webstorare 'Microsoft.Cdn/profiles/origingroups/origins@2022-11-01-preview' = {
  parent: profiles_MyFrontDoor_name_MyOriginGroup
  name: 'webStoreOriginGroup'
  properties: {
    hostName: webstorecname
    httpPort: 80
    httpsPort: 443
    originHostHeader: webstorecname
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
    enforceCertificateNameCheck: true
  }
}

resource profiles_MyFrontDoor_name_apis_cartroute 'Microsoft.Cdn/profiles/afdendpoints/routes@2022-11-01-preview' = {
  parent: profiles_MyFrontDoor_name_apis
  name: 'cartroute'
  properties: {
    customDomains: []
    originGroup: {
      id: profiles_MyFrontDoor_name_cartapiorigingroup.id
    }
    ruleSets: []
    supportedProtocols: ['Http', 'Https']
    patternsToMatch: ['/cart/*']
    forwardingProtocol: 'HttpOnly'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
    enabledState: 'Enabled'
  }
}

resource profiles_MyFrontDoor_name_web_MyRoute 'Microsoft.Cdn/profiles/afdendpoints/routes@2022-11-01-preview' = {
  parent: profiles_MyFrontDoor_name_web
  name: 'MyRoute'
  properties: {
    customDomains: []
    originGroup: {
      id: profiles_MyFrontDoor_name_MyOriginGroup.id
    }
    ruleSets: []
    supportedProtocols: ['Http', 'Https']
    patternsToMatch: ['/*']
    forwardingProtocol: 'HttpsOnly'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
    enabledState: 'Enabled'
  }
}

resource profiles_MyFrontDoor_name_apis_prodroute 'Microsoft.Cdn/profiles/afdendpoints/routes@2022-11-01-preview' = {
  parent: profiles_MyFrontDoor_name_apis
  name: 'prodroute'
  properties: {
    customDomains: []
    originGroup: {
      id: profiles_MyFrontDoor_name_prodapiorigingroup.id
    }
    ruleSets: []
    supportedProtocols: ['Http', 'Https']
    patternsToMatch: ['/prod/*']
    forwardingProtocol: 'HttpOnly'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Disabled'
    enabledState: 'Enabled'
  }
}

resource profiles_MyFrontDoor_name_images_routetoimages 'Microsoft.Cdn/profiles/afdendpoints/routes@2022-11-01-preview' = {
  parent: profiles_MyFrontDoor_name_images
  name: 'routetoimages'
  properties: {
    customDomains: []
    originGroup: {
      id: profiles_MyFrontDoor_name_imagesgroup.id
    }
    ruleSets: []
    supportedProtocols: ['Http', 'Https']
    patternsToMatch: ['/*']
    forwardingProtocol: 'MatchRequest'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
    enabledState: 'Enabled'
  }
}

// return the 3 endpoints
output webEndpoint string = profiles_MyFrontDoor_name_web.properties.hostName
output imagesEndpoint string = profiles_MyFrontDoor_name_images.properties.hostName
output VmApiEndpoint string = profiles_MyFrontDoor_name_apis.properties.hostName
