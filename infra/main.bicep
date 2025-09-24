targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@metadata({azd: {
  type: 'location'
  usageName: [
    'OpenAI.GlobalStandard.gpt-5-mini,10'
  ]}
})
param aiDeploymentsLocation string

@description('Id of the user or app to assign application roles')
param principalId string

@description('Principal type of user or app')
param principalType string

// Tags that should be applied to all resources.
// 
// Note that 'azd-service-name' tags should be applied separately to service host resources.
// Example usage:
//   tags: union(tags, { 'azd-service-name': <service name in azure.yaml> })
var tags = {
  'azd-env-name': environmentName
}

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}

module resources 'resources.bicep' = {
  scope: rg
  name: 'resources'
  params: {
    location: location
    tags: tags
    principalId: principalId
    principalType: principalType
    aiFoundryProjectEndpoint: aiModelsDeploy.outputs.ENDPOINT
  }
}

module aiModelsDeploy 'ai-project.bicep' = {
  scope: rg
  name: 'ai-project'
  params: {
    tags: tags
    location: aiDeploymentsLocation
    envName: environmentName
    principalId: principalId
    principalType: principalType
    deployments: [
      {
        name: 'gpt5MiniDeployment'
        model: {
          name: 'gpt-5-mini'
          format: 'OpenAI'
          version: '2025-08-07'
        }
        sku: {
          name: 'GlobalStandard'
          capacity: 10
        }
      }
    ]
  }
}
output AZURE_KEY_VAULT_ENDPOINT string = resources.outputs.AZURE_KEY_VAULT_ENDPOINT
output AZURE_KEY_VAULT_NAME string = resources.outputs.AZURE_KEY_VAULT_NAME
output AZURE_RESOURCE_VAULT_ID string = resources.outputs.AZURE_RESOURCE_VAULT_ID
output AZURE_RESOURCE_THEGLOBE_DB_DEV_ID string = resources.outputs.AZURE_RESOURCE_THEGLOBE_DB_DEV_ID
output AZURE_RESOURCE_STORAGE_ID string = resources.outputs.AZURE_RESOURCE_STORAGE_ID
output AZURE_AI_PROJECT_ENDPOINT string = aiModelsDeploy.outputs.ENDPOINT
output AZURE_RESOURCE_AI_PROJECT_ID string = aiModelsDeploy.outputs.projectId
