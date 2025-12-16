@description('The name of the Azure OpenAI service')
param name string

@description('The location for the Azure OpenAI service')
param location string = 'westus3'

@description('Tags to apply to the Azure OpenAI service')
param tags object = {}

@description('The SKU of the Azure OpenAI service')
param sku string = 'S0'

@description('GPT-4 model deployment configuration')
param gpt4DeploymentName string = 'gpt-4'

@description('GPT-4 model name - using gpt-4o which is available in westus3')
param gpt4ModelName string = 'gpt-4o'

@description('GPT-4 model version - using 2024-08-06 which is supported in westus3')
param gpt4ModelVersion string = '2024-08-06'

@description('GPT-4 deployment capacity')
param gpt4Capacity int = 10

@description('Secondary model deployment configuration')
param secondaryDeploymentName string = 'gpt-4o-mini'

@description('Secondary model name - using gpt-4o-mini as a cost-effective alternative')
param secondaryModelName string = 'gpt-4o-mini'

@description('Secondary model version')
param secondaryModelVersion string = '2024-07-18'

@description('Secondary deployment capacity')
param secondaryCapacity int = 10

resource openAIAccount 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: name
  location: location
  tags: tags
  kind: 'OpenAI'
  sku: {
    name: sku
  }
  properties: {
    customSubDomainName: name
    publicNetworkAccess: 'Enabled'
  }
}

resource gpt4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-10-01-preview' = {
  parent: openAIAccount
  name: gpt4DeploymentName
  sku: {
    name: 'Standard'
    capacity: gpt4Capacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: gpt4ModelName
      version: gpt4ModelVersion
    }
  }
}

resource secondaryDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-10-01-preview' = {
  parent: openAIAccount
  name: secondaryDeploymentName
  sku: {
    name: 'Standard'
    capacity: secondaryCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: secondaryModelName
      version: secondaryModelVersion
    }
  }
  dependsOn: [
    gpt4Deployment
  ]
}

@description('The resource ID of the Azure OpenAI service')
output id string = openAIAccount.id

@description('The name of the Azure OpenAI service')
output name string = openAIAccount.name

@description('The endpoint of the Azure OpenAI service')
output endpoint string = openAIAccount.properties.endpoint

@description('The primary key of the Azure OpenAI service')
@secure()
output key string = openAIAccount.listKeys().key1
