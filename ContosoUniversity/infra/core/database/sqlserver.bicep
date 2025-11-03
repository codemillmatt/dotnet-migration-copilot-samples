@description('Name of the SQL Server')
param name string

@description('Location for the resources')
param location string = resourceGroup().location

@description('Tags to apply to resources')
param tags object = {}

@description('Name of the database')
param databaseName string

@description('Principal ID to assign as SQL Admin')
param principalId string

@description('Principal name to assign as SQL Admin')
param principalName string

resource sqlServer 'Microsoft.Sql/servers@2023-02-01-preview' = {
  name: name
  location: location
  tags: tags
  properties: {
    administrators: {
      administratorType: 'ActiveDirectory'
      principalType: 'User'
      login: principalName
      sid: principalId
      tenantId: tenant().tenantId
      azureADOnlyAuthentication: false // Allow both Azure AD and SQL auth for flexibility
    }
    publicNetworkAccess: 'Enabled'
    minimalTlsVersion: '1.2'
  }

  resource database 'databases@2023-02-01-preview' = {
    name: databaseName
    location: location
    tags: tags
    sku: {
      name: 'Basic'
      tier: 'Basic'
      capacity: 5
    }
    properties: {
      collation: 'SQL_Latin1_General_CP1_CI_AS'
      maxSizeBytes: 2147483648 // 2GB
    }
  }

  resource firewallRules 'firewallRules@2023-02-01-preview' = {
    name: 'AllowAllWindowsAzureIps'
    properties: {
      startIpAddress: '0.0.0.0'
      endIpAddress: '0.0.0.0'
    }
  }
}

output AZURE_SQL_SERVER string = sqlServer.name
output AZURE_SQL_DATABASE string = databaseName
output connectionString string = 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName};Database=${databaseName};Authentication=Active Directory Default;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'