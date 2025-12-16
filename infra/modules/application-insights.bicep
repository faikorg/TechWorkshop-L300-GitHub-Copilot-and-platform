@description('The name of the application insights')
param name string

@description('The location for the application insights')
param location string = resourceGroup().location

@description('Tags to apply to the application insights')
param tags object = {}

@description('The resource ID of the log analytics workspace')
param workspaceId string

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: name
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspaceId
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

@description('The resource ID of the application insights')
output id string = applicationInsights.id

@description('The instrumentation key of the application insights')
output instrumentationKey string = applicationInsights.properties.InstrumentationKey

@description('The connection string of the application insights')
output connectionString string = applicationInsights.properties.ConnectionString
