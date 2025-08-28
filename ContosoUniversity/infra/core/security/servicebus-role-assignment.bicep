@description('Name of the Service Bus namespace')
param serviceBusNamespaceName string

@description('Principal ID to assign Service Bus permissions')
param principalId string

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' existing = {
  name: serviceBusNamespaceName
}

// Grant Service Bus Data Owner role to the container app's managed identity
resource serviceBusDataOwnerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(serviceBusNamespace.id, principalId, '090c5cfd-751d-490a-894a-3ce6f1109419')
  scope: serviceBusNamespace
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '090c5cfd-751d-490a-894a-3ce6f1109419') // Azure Service Bus Data Owner
    principalType: 'ServicePrincipal'
    principalId: principalId
  }
}

output roleAssignmentId string = serviceBusDataOwnerRoleAssignment.id