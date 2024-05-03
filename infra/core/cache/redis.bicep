param name string
param location string = resourceGroup().location
param tags object = {}

resource redisCache 'Microsoft.Cache/redis@2023-08-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'Basic'
      family: 'C'
      capacity: 0
    }
    enableNonSslPort: false
    publicNetworkAccess: 'Enabled'
  }
}

output host string = redisCache.properties.hostName
output port int = redisCache.properties.sslPort
output connectionString string = 'rediss://${redisCache.properties.hostName}:${redisCache.properties.sslPort}?password=${listKeys(redisCache.id, redisCache.apiVersion).primaryKey}'
