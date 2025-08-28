targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Id of the user or app to assign application roles')
param principalId string

// Optional parameters
@description('Name of the resource group')
param resourceGroupName string = ''

@description('Name of the SQL Server')
param sqlServerName string = ''

@description('Name of the SQL Database')
param sqlDatabaseName string = ''

@description('Name of the Service Bus namespace')
param serviceBusNamespaceName string = ''

@description('Name of the Container Apps environment')
param containerAppsEnvironmentName string = ''

@description('Name of the Container App')
param containerAppName string = ''

@description('Name of the Log Analytics workspace')
param logAnalyticsWorkspaceName string = ''

@description('Name of the Application Insights instance')
param applicationInsightsName string = ''

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = {
  'azd-env-name': environmentName
}

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

module monitoring './core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    location: location
    tags: tags
    logAnalyticsName: !empty(logAnalyticsWorkspaceName) ? logAnalyticsWorkspaceName : '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${resourceToken}'
  }
}

module containerAppsEnv './core/host/container-apps-environment.bicep' = {
  name: 'container-apps-environment'
  scope: rg
  params: {
    name: !empty(containerAppsEnvironmentName) ? containerAppsEnvironmentName : '${abbrs.appManagedEnvironments}${resourceToken}'
    location: location
    tags: tags
    logAnalyticsWorkspaceName: monitoring.outputs.logAnalyticsWorkspaceName
  }
}

module sqlServer './core/database/sqlserver.bicep' = {
  name: 'sqlserver'
  scope: rg
  params: {
    name: !empty(sqlServerName) ? sqlServerName : '${abbrs.sqlServers}${resourceToken}'
    location: location
    tags: tags
    databaseName: !empty(sqlDatabaseName) ? sqlDatabaseName : 'ContosoUniversity'
    principalId: principalId
    principalName: principalId
  }
}

// Create Service Bus first without container app permissions
module serviceBus './core/messaging/servicebus.bicep' = {
  name: 'servicebus'
  scope: rg
  params: {
    name: !empty(serviceBusNamespaceName) ? serviceBusNamespaceName : '${abbrs.serviceBusNamespaces}${resourceToken}'
    location: location
    tags: tags
    principalId: principalId
  }
}

module app './core/host/container-app.bicep' = {
  name: 'container-app'
  scope: rg
  params: {
    name: !empty(containerAppName) ? containerAppName : '${abbrs.containerAppsContainerApps}${resourceToken}'
    location: location
    tags: tags
    containerAppsEnvironmentName: containerAppsEnv.outputs.name
    containerRegistryName: ''
    env: [
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: monitoring.outputs.applicationInsightsConnectionString
      }
      {
        name: 'ConnectionStrings__DefaultConnection'
        value: 'Server=tcp:${sqlServer.outputs.AZURE_SQL_SERVER}.database.windows.net;Database=${sqlServer.outputs.AZURE_SQL_DATABASE};Authentication=Active Directory Default;'
      }
      {
        name: 'NotificationQueue__ServiceBusNamespace'
        value: '${serviceBus.outputs.name}.servicebus.windows.net'
      }
      {
        name: 'NotificationQueue__QueueName'
        value: 'notifications'
      }
      {
        name: 'AZURE_CLIENT_ID'
        value: app.outputs.identityClientId
      }
    ]
    imageName: 'mcr.microsoft.com/dotnet/samples:aspnetapp'
    targetPort: 8080
  }
}

// Add role assignments after container app is created
module sqlRoleAssignment './core/security/sql-role-assignment.bicep' = {
  name: 'sql-role-assignment'
  scope: rg
  params: {
    sqlServerName: sqlServer.outputs.AZURE_SQL_SERVER
    principalId: app.outputs.identityPrincipalId
  }
}

module serviceBusAppRoleAssignment './core/security/servicebus-role-assignment.bicep' = {
  name: 'servicebus-app-role-assignment'
  scope: rg
  params: {
    serviceBusNamespaceName: serviceBus.outputs.name
    principalId: app.outputs.identityPrincipalId
  }
}

// App outputs
output APPLICATIONINSIGHTS_CONNECTION_STRING string = monitoring.outputs.applicationInsightsConnectionString
output AZURE_CONTAINER_APPS_ENVIRONMENT_ID string = containerAppsEnv.outputs.id
output AZURE_CONTAINER_APPS_ENVIRONMENT_NAME string = containerAppsEnv.outputs.name
output AZURE_CONTAINER_APP_NAME string = app.outputs.name
output AZURE_CONTAINER_APP_FQDN string = app.outputs.fqdn
output AZURE_SQL_SERVER string = sqlServer.outputs.AZURE_SQL_SERVER
output AZURE_SQL_DATABASE string = sqlServer.outputs.AZURE_SQL_DATABASE
output AZURE_SERVICE_BUS_NAMESPACE string = serviceBus.outputs.nameoutput AZURE_SERVICE_BUS_NAMESPACE string = serviceBus.outputs.name