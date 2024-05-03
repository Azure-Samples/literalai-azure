param name string
param location string = resourceGroup().location
param tags object = {}

resource containerEnv 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    zoneRedundant: false
  }
}

output id string = containerEnv.id
output defaultDomain string = containerEnv.properties.defaultDomain
