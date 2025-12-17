@description('The location for the workbook resource')
param location string = resourceGroup().location

@description('The name of the workbook')
param workbookName string

@description('The display name of the workbook')
param workbookDisplayName string = 'AI Services Observability'

@description('The resource ID of the Log Analytics workspace')
param logAnalyticsWorkspaceId string

@description('Tags for the workbook resource')
param tags object = {}

@description('The workbook content from JSON file')
param workbookContent object

resource workbook 'Microsoft.Insights/workbooks@2023-06-01' = {
  name: workbookName
  location: location
  tags: tags
  kind: 'shared'
  properties: {
    displayName: workbookDisplayName
    serializedData: string(workbookContent)
    version: '1.0'
    sourceId: logAnalyticsWorkspaceId
    category: 'Azure Monitor'
  }
}

output workbookId string = workbook.id
output workbookName string = workbook.name
