param accountName string
param location string = resourceGroup().location
param tags object = {}
param cosmosDatabaseName string = ''
param keyVaultResourceId string
@description('Optional capabilities to pass to the Cosmos DB account (e.g., serverless).')
param capabilities array = []
@description('Enable Cosmos DB free tier for the account where available.')
param enableFreeTier bool = false
param connectionStringKey string = 'AZURE-COSMOS-CONNECTION-STRING'
param collections array = [
  {
    name: 'Post'
    id: 'Post'
    shardKey: {
      keys: [
        'Hash'
      ]
    }
    indexes: [
      {
        key: {
          keys: [
            '_id'
          ]
        }
      }
    ]
  }
]

var defaultDatabaseName = 'TheGlobeDev'
var actualDatabaseName = !empty(cosmosDatabaseName) ? cosmosDatabaseName : defaultDatabaseName

module cosmos 'br/public:avm/res/document-db/database-account:0.6.0' = {
  name: 'cosmos-mongo'
  params: {
    locations: [
      {
        failoverPriority: 0
        isZoneRedundant: false
        locationName: location
      }
    ]
  name: accountName
  location: location
  // The underlying ARM/Bicep module expects the property 'capabilitiesToAdd' for adding capabilities
  capabilitiesToAdd: capabilities
  enableFreeTier: enableFreeTier
    mongodbDatabases: [
      {
        name: actualDatabaseName
        tags: tags
        collections: collections
      }
    ]
    secretsExportConfiguration: {
      keyVaultResourceId: keyVaultResourceId
      primaryWriteConnectionStringSecretName: connectionStringKey
    }
  }
}

output connectionStringKey string = connectionStringKey
output databaseName string = actualDatabaseName
output endpoint string = cosmos.outputs.endpoint
