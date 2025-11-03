#!/bin/bash

# Post-deployment script to configure Azure SQL Database for managed identity
# This script should be run after the infrastructure is deployed

# Configuration
RESOURCE_GROUP_NAME="${AZURE_RESOURCE_GROUP:-rg-contoso-university}"
SQL_SERVER_NAME="${AZURE_SQL_SERVER}"
DATABASE_NAME="${AZURE_SQL_DATABASE:-ContosoUniversity}"
CONTAINER_APP_NAME="${AZURE_CONTAINER_APP_NAME}"

echo "Setting up Azure SQL Database managed identity permissions..."
echo "Resource Group: $RESOURCE_GROUP_NAME"
echo "SQL Server: $SQL_SERVER_NAME"
echo "Database: $DATABASE_NAME"
echo "Container App: $CONTAINER_APP_NAME"

# Get the managed identity name
IDENTITY_NAME="${CONTAINER_APP_NAME}-identity"
echo "Managed Identity: $IDENTITY_NAME"

# Get current user for Azure AD authentication
CURRENT_USER=$(az account show --query user.name -o tsv)
echo "Current user: $CURRENT_USER"

# SQL script to create user and assign permissions
SQL_SCRIPT="
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = '${IDENTITY_NAME}')
BEGIN
    PRINT 'Creating user for managed identity: ${IDENTITY_NAME}';
    CREATE USER [${IDENTITY_NAME}] FROM EXTERNAL PROVIDER;
    
    PRINT 'Assigning database roles...';
    ALTER ROLE db_datareader ADD MEMBER [${IDENTITY_NAME}];
    ALTER ROLE db_datawriter ADD MEMBER [${IDENTITY_NAME}];
    ALTER ROLE db_ddladmin ADD MEMBER [${IDENTITY_NAME}];
    
    PRINT 'Granting additional permissions...';
    GRANT CREATE TABLE TO [${IDENTITY_NAME}];
    GRANT ALTER ON SCHEMA::dbo TO [${IDENTITY_NAME}];
    
    PRINT 'Managed Identity user configured successfully';
END
ELSE
BEGIN
    PRINT 'Managed Identity user already exists: ${IDENTITY_NAME}';
END
"

echo "Executing SQL script..."

# Execute the SQL script using Azure CLI
az sql db query \
    --server "$SQL_SERVER_NAME" \
    --database "$DATABASE_NAME" \
    --query "$SQL_SCRIPT" \
    --output table

if [ $? -eq 0 ]; then
    echo "? SQL Database managed identity configuration completed successfully"
else
    echo "? Failed to configure managed identity permissions"
    echo "Please run the following SQL script manually as an Azure AD admin:"
    echo ""
    echo "$SQL_SCRIPT"
    exit 1
fi