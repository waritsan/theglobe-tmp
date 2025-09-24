@description('The location used for all deployed resources')
param location string = resourceGroup().location

@description('Tags that will be applied to all resources')
param tags object = {}

@description('Enable Azure Cosmos DB Free Tier (if supported by the module/provider)')
param enableCosmosFreeTier bool = true


@description('Id of the user or app to assign application roles')
param principalId string

@description('Principal type of user or app')
param principalType string

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = uniqueString(subscription().id, resourceGroup().id, location)
module cosmos 'br/public:avm/res/document-db/database-account:0.8.1' = {
  name: 'cosmos'
  params: {
    name: '${abbrs.documentDBDatabaseAccounts}${resourceToken}'
    tags: tags
    location: location
    locations: [
      {
        failoverPriority: 0
        isZoneRedundant: false
        locationName: location
      }
    ]
    networkRestrictions: {
      ipRules: []
      virtualNetworkRules: []
      publicNetworkAccess: 'Enabled'
    }
    sqlDatabases: [
      {
        name: 'theglobe-db-dev'
        containers: [
        ]
      }
    ]
    sqlRoleAssignmentsPrincipalIds: [
      principalId
    ]
    sqlRoleDefinitions: [
      {
        name: 'service-access-cosmos-sql-role'
      }
    ]
    // Opt-in to Cosmos DB Free Tier if the module exposes this option.
    enableFreeTier: enableCosmosFreeTier
    capabilitiesToAdd: [ 'EnableServerless' ]
  }
}
var storageAccountName = '${abbrs.storageStorageAccounts}${resourceToken}'
module storageAccount 'br/public:avm/res/storage/storage-account:0.17.2' = {
  name: 'storageAccount'
  params: {
    name: storageAccountName
    allowSharedKeyAccess: false
    publicNetworkAccess: 'Enabled'
    blobServices: {
      containers: [
        {
          name: 'theglobe-sa-dev'
        }
      ]
    }
    location: location
    roleAssignments: concat(
      principalType == 'User' ? [
        {  
          principalId: principalId
          principalType: 'User'
          roleDefinitionIdOrName: 'Storage Blob Data Contributor'  
        }
      ] : [],
      [
      ]
    )
    networkAcls: {
      defaultAction: 'Allow'
    }
    tags: tags
  }
}

@description('Enable creation of an Azure Static Web App')
param enableStaticWebApp bool = true

@description('Repository URL for the Static Web App (e.g. https://github.com/owner/repo)')
param staticSiteRepositoryUrl string = ''

@description('Branch for the Static Web App repository')
param staticSiteBranch string = 'main'

@description('App location (relative path within the repo)')
param staticAppLocation string = '/'

@description('API location (relative path within the repo)')
param staticApiLocation string = 'api'

@description('App artifact (output) location after build')
param staticAppArtifactLocation string = 'build'

// Create an Azure Static Web App (minimal configuration). The service will
// create a GitHub Action if repository details are provided.
resource staticSite 'Microsoft.Web/staticSites@2022-03-01' = if (enableStaticWebApp) {
  // use the existing abbreviation key from abbreviations.json: "webStaticSites"
  name: '${abbrs.webStaticSites}${resourceToken}'
  location: location
  tags: tags
  sku: {
    name: 'Free'
  }
  properties: {
    repositoryUrl: staticSiteRepositoryUrl
    branch: staticSiteBranch
    buildProperties: {
      appLocation: staticAppLocation
      apiLocation: staticApiLocation
      appArtifactLocation: staticAppArtifactLocation
    }
  }
}

// Create a keyvault to store secrets
module keyVault 'br/public:avm/res/key-vault/vault:0.12.0' = {
  name: 'keyvault'
  params: {
    name: '${abbrs.keyVaultVaults}${resourceToken}'
    location: location
    tags: tags
    enableRbacAuthorization: false
    accessPolicies: [
      {
        objectId: principalId
        permissions: {
          secrets: [ 'get', 'list', 'set' ]
        }
      }
    ]
    secrets: [
    ]
  }
}
output AZURE_KEY_VAULT_ENDPOINT string = keyVault.outputs.uri
output AZURE_KEY_VAULT_NAME string = keyVault.outputs.name
output AZURE_RESOURCE_VAULT_ID string = keyVault.outputs.resourceId
output AZURE_RESOURCE_THEGLOBE_DB_DEV_ID string = '${cosmos.outputs.resourceId}/sqlDatabases/theglobe-db-dev'
output AZURE_RESOURCE_STORAGE_ID string = storageAccount.outputs.resourceId
