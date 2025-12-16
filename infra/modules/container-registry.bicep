@description('The name of the container registry')
param name string

@description('The location for the container registry')
param location string = resourceGroup().location

@description('Tags to apply to the container registry')
param tags object = {}

@description('The SKU of the container registry')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Basic'

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
    zoneRedundancy: 'Disabled'
  }
}

@description('The name of the container registry')
output name string = containerRegistry.name

@description('The login server of the container registry')
output loginServer string = containerRegistry.properties.loginServer

@description('The resource ID of the container registry')
output id string = containerRegistry.id
