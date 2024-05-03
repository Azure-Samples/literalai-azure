param tags object = {}
param location string = resourceGroup().location
param name string
param sku string = 'Standard_LRS'
param kind string = 'StorageV2'
param accessTier string = 'Hot'

param allowSharedKeyAccess bool = true
param minimumTlsVersion string = 'TLS1_2'

param containerNames array = []

resource blobStorage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  kind: kind
  properties: {
    accessTier: accessTier
    allowBlobPublicAccess: false
    allowSharedKeyAccess: allowSharedKeyAccess
    minimumTlsVersion: minimumTlsVersion
    supportsHttpsTrafficOnly: true
  }

  resource blobService 'blobServices' = {
    name: 'default'
    properties: {
      cors: {
        corsRules: [
          {
            allowedOrigins: [
              '*'
            ]
            allowedMethods: [
              'GET'
              'HEAD'
              'POST'
              'PUT'
              'DELETE'
              'OPTIONS'
              'MERGE'
              'PATCH'
            ]
            allowedHeaders: [
              '*'
            ]
            exposedHeaders: [
              '*'
            ]
            maxAgeInSeconds: 3600
          }
        ]
      }
    }

    resource container 'containers' = [for name in containerNames: {
      name: name
      properties: {
        publicAccess: 'None'
      }
    }]
  }
}

output storageAccountName string = blobStorage.name
output primaryEndpoints object = blobStorage.properties.primaryEndpoints
output storageAccountKey string = blobStorage.listKeys().keys[0].value
