targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name to prefix all resources')
param name string = 'babybuddy'

@minLength(1)
@description('Primary location for all resources')
param location string = 'eastus'

@secure()
param databasePassword string

@secure()
param nextAuthSecret string

@description('Id of the user or app to assign application roles')
param principalId string = ''

@secure()
param dockerPat string

param dockerImageVersion string

param authClientId string = ''
@secure()
param authClientSecret string = ''
param authTenantId string = ''

var databaseAdmin = 'dbadmin'
var databaseName = 'literalai'
var resourceToken = toLower(uniqueString(subscription().id, name, location))

var storageAccountName = 'literalstorageaccount'
var storageContainerName = 'literalblobcontainer'

param useAuthentication bool = false

var tags = { 'azd-env-name': name }
var prefix = '${name}-${resourceToken}'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${name}-resource-group'
  location: location
  tags: tags
}

// Store secrets in a keyvault
module keyVault './core/security/keyvault.bicep' = {
  name: 'keyvault'
  scope: resourceGroup
  params: {
    name: '${replace(take(prefix, 17), '-', '')}-vault'
    location: location
    tags: tags
  }
}

// Give the principal access to KeyVault
module principalKeyVaultAccess './core/security/keyvault-access.bicep' = {
  name: 'keyvault-access-${principalId}'
  scope: resourceGroup
  params: {
    keyVaultName: keyVault.outputs.name
    principalId: principalId
  }
}

module postgresServer 'core/database/pg-flexibleserver.bicep' = {
  name: 'postgresql'
  scope: resourceGroup
  params: {
    name: '${prefix}-postgresql'
    location: location
    tags: tags
    sku: {
      name: 'Standard_B1ms'
      tier: 'Burstable'
    }
    storage: {
      storageSizeGB: 32
    }
    version: '15'
    administratorLogin: databaseAdmin
    administratorLoginPassword: databasePassword
    databaseNames: [ databaseName ]
    allowAzureIPsFirewall: true
  }
}

module redisCache 'core/cache/redis.bicep' = {
  name: 'redis'
  scope: resourceGroup
  params: {
    name: '${prefix}-redis'
    location: location
    tags: tags
  }
}

module blobStorage 'core/file-storage/blobstorage.bicep' = {
  name: 'blobstorage'
  scope: resourceGroup
  params: {
    name: storageAccountName
    containerNames: [ storageContainerName ]
    location: location
    tags: tags
  }
}

module containerAppEnv 'core/host/container-app-env.bicep' = {
  name: 'container-env'
  scope: resourceGroup
  params: {
    name: containerAppName
    location: location
    tags: tags
  }
}

var secrets = [
  {
    name: 'DATABASEPASSWORD'
    value: databasePassword
  }
  {
    name: 'NEXTAUTHSECRET'
    value: nextAuthSecret
  }
]

module keyVaultSecrets './core/security/keyvault-secret.bicep' = [for secret in secrets: {
  name: 'keyvault-secret-${secret.name}'
  scope: resourceGroup
  params: {
    keyVaultName: keyVault.outputs.name
    name: secret.name
    secretValue: secret.value
  }
}]

var containerAppName = '${prefix}-app'
module containerApp 'core/host/container-app.bicep' = {
  name: 'container'
  scope: resourceGroup
  params: {
    name: containerAppName
    location: location
    tags: tags
    containerEnvId: containerAppEnv.outputs.id
    imageName: 'docker.io/literalai/platform-distrib:${dockerImageVersion}'
    targetPort: 3000
    env: [
      {
        name: 'LITERAL_DOCKER_PAT'
        secretRef: 'dockerpat'
      }
      {
        name: 'LITERAL_CLIENT_ID'
        secretRef: 'literalClientId'
      }
      {
        name: 'LITERAL_AUTH_TOKEN'
        secretRef: 'literalAuthToken'
      }
      {
        name: 'DATABASE_HOST'
        value: postgresServer.outputs.fqdn
      }
      {
        name: 'DATABASE_NAME'
        value: databaseName
      }
      {
        name: 'DATABASE_USERNAME'
        value: databaseAdmin
      }
      {
        name: 'DATABASE_PASSWORD'
        secretRef: 'databasepassword'
      }
      {
        name: 'DATABASE_SSL'
        value: 'true'
      }
      {
        name: 'REDIS_URL'
        secretRef: 'redisurl'
      }
      {
        name: 'BUCKET_NAME'
        value: storageContainerName
      }
      {
        name: 'NEXTAUTH_URL'
        value: 'https://${containerAppName}.${containerAppEnv.outputs.defaultDomain}'
      }
      {
        name: 'NEXTAUTH_SECRET'
        secretRef: 'nextauthsecret'
      }
      {
        name: 'APP_AZURE_STORAGE_ACCOUNT'
        value: blobStorage.outputs.storageAccountName
      }
      {
        name: 'APP_AZURE_STORAGE_ACCESS_KEY'
        value: blobStorage.outputs.storageAccountKey
      }
      {
        name: 'AZURE_AD_CLIENT_ID'
        value: authClientId
      }
      {
        name: 'AZURE_AD_CLIENT_SECRET'
        secretRef: 'authclientsecret'
      }
      {
        name: 'AZURE_AD_TENANT_ID'
        value: authTenantId
      }
      {
        name: 'ENABLE_CREDENTIALS_AUTH'
        value: useAuthentication ? 'false' : 'true'
      }
      {
        name: 'GATEWAY_URL'
        value: 'http://localhost:8787'
      }
    ]
    secrets: {
      redisurl: redisCache.outputs.connectionString
      databasepassword: databasePassword
      nextauthsecret: nextAuthSecret
      dockerpat: dockerPat
      authclientsecret: authClientSecret
    }
  }
}

output SERVICE_APP_URI string = containerApp.outputs.uri
output AZURE_KEY_VAULT_NAME string = keyVault.outputs.name
