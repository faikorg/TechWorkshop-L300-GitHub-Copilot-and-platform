@description('The name of the app service')
param name string

@description('The location for the app service')
param location string = resourceGroup().location

@description('Tags to apply to the app service')
param tags object = {}

@description('The resource ID of the app service plan')
param appServicePlanId string

@description('The login server of the container registry')
param containerRegistryLoginServer string

@description('The name of the container image')
param containerImageName string = 'zava-storefront:latest'

@description('The connection string for application insights')
@secure()
param applicationInsightsConnectionString string

resource appService 'Microsoft.Web/sites@2023-01-01' = {
  name: name
  location: location
  tags: tags
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerRegistryLoginServer}/${containerImageName}'
      acrUseManagedIdentityCreds: true
      alwaysOn: true
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsightsConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_Mode'
          value: 'recommended'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${containerRegistryLoginServer}'
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
      ]
    }
  }
}

@description('The resource ID of the app service')
output id string = appService.id

@description('The name of the app service')
output name string = appService.name

@description('The principal ID of the system assigned managed identity')
output principalId string = appService.identity.principalId

@description('The default hostname of the app service')
output defaultHostname string = appService.properties.defaultHostName
