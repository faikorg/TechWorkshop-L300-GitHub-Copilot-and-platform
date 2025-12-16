@description('The principal ID to assign the role to')
param principalId string

@description('The role definition ID to assign')
param roleDefinitionId string

@description('The resource ID of the target resource')
param targetResourceId string

@description('The principal type of the assignee')
@allowed([
  'ServicePrincipal'
  'User'
  'Group'
])
param principalType string = 'ServicePrincipal'

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(targetResourceId, principalId, roleDefinitionId)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    principalType: principalType
  }
}

@description('The ID of the role assignment')
output id string = roleAssignment.id
