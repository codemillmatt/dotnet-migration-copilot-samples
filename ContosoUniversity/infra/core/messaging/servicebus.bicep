@description('Name of the Service Bus namespace')
param name string

@description('Location for the resources')
param location string = resourceGroup().location

@description('Tags to apply to resources')
param tags object = {}

@description('Principal ID to grant Service Bus permissions')
param principalId string

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }

  resource notificationsQueue 'queues@2022-10-01-preview' = {
    name: 'notifications'
    properties: {
      maxSizeInMegabytes: 1024
      defaultMessageTimeToLive: 'P14D' // 14 days
      duplicateDetectionHistoryTimeWindow: 'PT10M' // 10 minutes
      enableBatchedOperations: true
      deadLetteringOnMessageExpiration: true
      maxDeliveryCount: 10
    }
  }
}

// Grant Service Bus Data Owner role to the deployment principal (for setup)
resource serviceBusDataOwnerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(serviceBusNamespace.id, principalId, '090c5cfd-751d-490a-894a-3ce6f1109419')
  scope: serviceBusNamespace
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '090c5cfd-751d-490a-894a-3ce6f1109419') // Azure Service Bus Data Owner
    principalType: 'User'
    principalId: principalId
  }
}

output id string = serviceBusNamespace.id
output name string = serviceBusNamespace.name
output endpoint string = serviceBusNamespace.properties.serviceBusEndpoint