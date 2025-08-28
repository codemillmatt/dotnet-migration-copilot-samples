@description('Name of the SQL Server')
param sqlServerName string

@description('Principal ID to assign SQL permissions')
param principalId string

resource sqlServer 'Microsoft.Sql/servers@2023-02-01-preview' existing = {
  name: sqlServerName
}

// Grant SQL DB Contributor role to the container app's managed identity
resource sqlDbContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(sqlServer.id, principalId, '9b7fa17d-e63e-47b0-bb0a-15c516ac86ec')
  scope: sqlServer
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '9b7fa17d-e63e-47b0-bb0a-15c516ac86ec') // SQL DB Contributor
    principalType: 'ServicePrincipal'
    principalId: principalId
  }
}

output roleAssignmentId string = sqlDbContributorRoleAssignment.id