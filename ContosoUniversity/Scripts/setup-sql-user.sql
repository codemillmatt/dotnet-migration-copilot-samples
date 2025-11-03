-- Simplified script for Container App managed identity setup
-- This script creates a user for the Container App's managed identity
-- and grants necessary permissions for Entity Framework operations
-- Note: This version is optimized for Azure CLI execution

-- Create user for managed identity (ca-c5nyxvpm7xvwu)
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'ca-c5nyxvpm7xvwu' AND type = 'E')
    CREATE USER [ca-c5nyxvpm7xvwu] FROM EXTERNAL PROVIDER;

-- Grant database roles
ALTER ROLE db_datareader ADD MEMBER [ca-c5nyxvpm7xvwu];
ALTER ROLE db_datawriter ADD MEMBER [ca-c5nyxvpm7xvwu];
ALTER ROLE db_ddladmin ADD MEMBER [ca-c5nyxvpm7xvwu];

-- Grant additional permissions for Entity Framework
GRANT CREATE TABLE TO [ca-c5nyxvpm7xvwu];
GRANT ALTER ON SCHEMA::dbo TO [ca-c5nyxvpm7xvwu];
GRANT EXECUTE TO [ca-c5nyxvpm7xvwu];
GRANT CREATE PROCEDURE TO [ca-c5nyxvpm7xvwu];
GRANT CREATE VIEW TO [ca-c5nyxvpm7xvwu];
GRANT CREATE FUNCTION TO [ca-c5nyxvpm7xvwu];
GRANT VIEW DEFINITION ON SCHEMA::dbo TO [ca-c5nyxvpm7xvwu];
GRANT REFERENCES ON SCHEMA::dbo TO [ca-c5nyxvpm7xvwu];
GRANT INSERT ON SCHEMA::dbo TO [ca-c5nyxvpm7xvwu];
GRANT UPDATE ON SCHEMA::dbo TO [ca-c5nyxvpm7xvwu];
GRANT DELETE ON SCHEMA::dbo TO [ca-c5nyxvpm7xvwu];
GRANT SELECT ON SCHEMA::dbo TO [ca-c5nyxvpm7xvwu];

-- Verify the user was created and permissions granted
SELECT 
    dp.name AS PrincipalName,
    dp.type_desc AS PrincipalType,
    r.name AS RoleName
FROM sys.database_role_members rm
JOIN sys.database_principals dp ON rm.member_principal_id = dp.principal_id
JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
WHERE dp.name = 'ca-c5nyxvpm7xvwu'
ORDER BY r.name;