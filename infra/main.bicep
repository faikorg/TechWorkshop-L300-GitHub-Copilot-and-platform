targetScope = 'resourceGroup'

@description('The environment name (e.g., dev, staging, prod)')
@minLength(1)
@maxLength(10)
param environmentName string

@description('The location for all resources')
param location string = resourceGroup().location

@description('The base name for resources')
param baseName string = 'zava-storefront'

@description('Tags to apply to all resources')
param tags object = {
  Environment: environmentName
  Application: 'ZavaStorefront'
  ManagedBy: 'AzureDeveloperCLI'
}

// Generate unique suffix for globally unique names
var uniqueSuffix = uniqueString(resourceGroup().id)

// Resource names
var acrName = 'acr${replace(baseName, '-', '')}${uniqueSuffix}'
var appServicePlanName = 'asp-${baseName}-${environmentName}'
var appServiceName = 'app-${baseName}-${environmentName}-${uniqueSuffix}'
var logAnalyticsName = 'log-${baseName}-${environmentName}'
var appInsightsName = 'appi-${baseName}-${environmentName}'
var openAiName = 'openai-${baseName}-${environmentName}-${uniqueSuffix}'

// Built-in Azure RBAC role IDs
var acrPullRoleId = '7f951dda-4ed3-4680-a7ca-43fe172d538d' // AcrPull
var cognitiveServicesOpenAIUserRoleId = '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd' // Cognitive Services OpenAI User

// Deploy Log Analytics Workspace
module logAnalytics './modules/log-analytics.bicep' = {
  name: 'log-analytics-deployment'
  params: {
    name: logAnalyticsName
    location: location
    tags: tags
    retentionInDays: 30
  }
}

// Deploy Application Insights
module applicationInsights './modules/application-insights.bicep' = {
  name: 'application-insights-deployment'
  params: {
    name: appInsightsName
    location: location
    tags: tags
    workspaceId: logAnalytics.outputs.id
  }
}

// Deploy Container Registry
module containerRegistry './modules/container-registry.bicep' = {
  name: 'container-registry-deployment'
  params: {
    name: acrName
    location: location
    tags: tags
    sku: 'Basic'
  }
}

// Deploy App Service Plan
module appServicePlan './modules/app-service-plan.bicep' = {
  name: 'app-service-plan-deployment'
  params: {
    name: appServicePlanName
    location: location
    tags: tags
    sku: {
      name: 'B1'
      tier: 'Basic'
      capacity: 1
    }
  }
}

// Deploy App Service
module appService './modules/app-service.bicep' = {
  name: 'app-service-deployment'
  params: {
    name: appServiceName
    location: location
    tags: tags
    appServicePlanId: appServicePlan.outputs.id
    containerRegistryLoginServer: containerRegistry.outputs.loginServer
    containerImageName: 'zava-storefront:latest'
    applicationInsightsConnectionString: applicationInsights.outputs.connectionString
    openAiEndpoint: openAi.outputs.endpoint
    openAiDeploymentName: 'gpt-4o-mini'
  }
}

// Deploy Azure OpenAI Service
module openAi './modules/openai.bicep' = {
  name: 'openai-deployment'
  params: {
    name: openAiName
    location: 'westus3' // Required for GPT-4o availability
    tags: tags
    sku: 'S0'
    gpt4DeploymentName: 'gpt-4'
    gpt4ModelName: 'gpt-4o'
    gpt4ModelVersion: '2024-08-06'
    gpt4Capacity: 10
    secondaryDeploymentName: 'gpt-4o-mini'
    secondaryModelName: 'gpt-4o-mini'
    secondaryModelVersion: '2024-07-18'
    secondaryCapacity: 10
  }
}

// Assign AcrPull role to App Service managed identity
module acrPullRoleAssignment './modules/role-assignment.bicep' = {
  name: 'acr-pull-role-assignment'
  params: {
    principalId: appService.outputs.principalId
    roleDefinitionId: acrPullRoleId
    targetResourceId: containerRegistry.outputs.id
    principalType: 'ServicePrincipal'
  }
}

// Assign Cognitive Services OpenAI User role to App Service managed identity
module openAiRoleAssignment './modules/role-assignment.bicep' = {
  name: 'openai-user-role-assignment'
  params: {
    principalId: appService.outputs.principalId
    roleDefinitionId: cognitiveServicesOpenAIUserRoleId
    targetResourceId: openAi.outputs.id
    principalType: 'ServicePrincipal'
  }
}

// Outputs
@description('The name of the container registry')
output containerRegistryName string = containerRegistry.outputs.name

@description('The login server of the container registry')
output containerRegistryLoginServer string = containerRegistry.outputs.loginServer

@description('The name of the app service')
output appServiceName string = appService.outputs.name

@description('The default hostname of the app service')
output appServiceHostname string = appService.outputs.defaultHostname

@description('The URL of the app service')
output appServiceUrl string = 'https://${appService.outputs.defaultHostname}'

@description('The name of the application insights')
output applicationInsightsName string = appInsightsName

@description('The connection string for application insights')
@secure()
output applicationInsightsConnectionString string = applicationInsights.outputs.connectionString

@description('The name of the Azure OpenAI service')
output openAiName string = openAi.outputs.name

@description('The endpoint of the Azure OpenAI service')
output openAiEndpoint string = openAi.outputs.endpoint

@description('The resource group name')
output resourceGroupName string = resourceGroup().name

@description('The location of the resources')
output resourceLocation string = location
