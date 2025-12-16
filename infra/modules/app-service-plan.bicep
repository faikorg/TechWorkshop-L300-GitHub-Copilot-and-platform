@description('The name of the app service plan')
param name string

@description('The location for the app service plan')
param location string = resourceGroup().location

@description('Tags to apply to the app service plan')
param tags object = {}

@description('The SKU configuration for the app service plan')
param sku object = {
  name: 'B1'
  tier: 'Basic'
  capacity: 1
}

resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: name
  location: location
  tags: tags
  sku: sku
  kind: 'linux'
  properties: {
    reserved: true
  }
}

@description('The resource ID of the app service plan')
output id string = appServicePlan.id

@description('The name of the app service plan')
output name string = appServicePlan.name
