---------------------------ADMIN------------------------------------------------------------------------
-- 1. Crear el login para el servidor
CREATE LOGIN messi WITH PASSWORD = 'basededatos';

-- 2. Cambiar al contexto de la base de datos Com5600G12
USE Com5600G12;

-- 3. Crear el usuario en la base de datos 'Com5600G12' asociando el login 'fabricio'
CREATE USER mateo FOR LOGIN messi;

-- 4. Asignar el rol 'sysadmin' al usuario 'fabricio' (permiso completo)
ALTER SERVER ROLE sysadmin ADD MEMBER fabricio;

-- Confirmaci�n de la creaci�n
PRINT 'El usuario fabricio ha sido creado con permisos de administrador';



-----------------------------------SUPERVISOR------------------------------------------------------------
-- Crear login para 'martin'
CREATE LOGIN martin WITH PASSWORD = 'tincho32';

-- Usar la base de datos 'Com5600G12'
USE Com5600G12;

-- Crear el usuario 'martin' en la base de datos 'Com5600G12'
CREATE USER martin FOR LOGIN martin;

-- Asignar el rol 'Supervisor' al usuario 'martin'
EXEC sp_addrolemember 'Supervisor', 'martin';

PRINT 'Usuario "martin" creado exitosamente con el rol Supervisor.';
--------------------------------------------------------------------------------

USE Com5600G12



CREATE OR ALTER PROCEDURE Autenticacion.CrearRolesConPermisos --CREO LOS ROLES EXISTENTES EN MI BD
AS
BEGIN
    -- Verificar si el rol Supervisor ya existe, si no lo crea
    IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Supervisor')
    BEGIN
        -- Crear el rol Supervisor
        CREATE ROLE Supervisor;
        PRINT 'Rol Supervisor creado';
        
        -- Asignar permisos totales (SELECT, INSERT, UPDATE, DELETE y EXECUTE) sobre los esquemas Ventas y Supermercado
        GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Ventas TO Supervisor;
        GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Supermercado TO Supervisor;
        GRANT EXECUTE ON SCHEMA::Ventas TO Supervisor;
        GRANT EXECUTE ON SCHEMA::Supermercado TO Supervisor;
        PRINT 'Permisos totales asignados al rol Supervisor';
    END
    ELSE
    BEGIN
        PRINT 'El rol Supervisor ya existe';
    END

    -- Verificar si el rol Empleado ya existe, si no lo crea
    IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Empleado')
    BEGIN
        -- Crear el rol Empleado
        CREATE ROLE Empleado;
        PRINT 'Rol Empleado creado';
        
        -- Asignar permisos solo para ejecutar procedimientos almacenados en los esquemas Ventas y Supermercado
        GRANT EXECUTE ON SCHEMA::Ventas TO Empleado;
        GRANT EXECUTE ON SCHEMA::Supermercado TO Empleado;
        PRINT 'Permiso de EXECUTE asignado al rol Empleado';
    END
    ELSE
    BEGIN
        PRINT 'El rol Empleado ya existe';
    END
END;
GO



CREATE OR ALTER PROCEDURE Autenticacion.CrearLoginUser
    @LoginUsuario NVARCHAR(100),
    @Contrase�a NVARCHAR(100)
AS
BEGIN
    -- Verificar si el login ya existe
    IF EXISTS (SELECT * FROM sys.server_principals WHERE name = @LoginUsuario)
    BEGIN
        RAISERROR('Error: El login ya existe', 16, 1);
        RETURN;
    END

    -- Crear un nuevo login usando SQL din�mico
    DECLARE @SqlLogin NVARCHAR(MAX);
    SET @SqlLogin = 'CREATE LOGIN ' + QUOTENAME(@LoginUsuario) + ' WITH PASSWORD = ''' + @Contrase�a + '''';
    EXEC sp_executesql @SqlLogin;
    PRINT 'Login creado exitosamente';

    -- Verificar si la base de datos 'Com5600G12' existe
    IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Com5600G12')
    BEGIN
        -- Crear el usuario en la base de datos 'Com5600G12' usando el mismo nombre que el login
        DECLARE @SqlUsuario NVARCHAR(MAX);
        
        SET @SqlUsuario = '
            USE Com5600G12;
            IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N''' + @LoginUsuario + ''')
            BEGIN
                CREATE USER ' + QUOTENAME(@LoginUsuario) + ' FOR LOGIN ' + QUOTENAME(@LoginUsuario) + ';
                PRINT ''Usuario creado exitosamente en la base de datos Com5600G12'';

                -- Asignar el rol ''Empleado'' autom�ticamente
                EXEC sp_addrolemember @RoleName = N''Empleado'', @MemberName = N''' + @LoginUsuario + ''';
                PRINT ''Rol Empleado asignado exitosamente a ' + @LoginUsuario + ''';
            END
            ELSE
            BEGIN
                PRINT ''El usuario ya existe en la base de datos Com5600G12'';
            END';
        
        -- Ejecutar el SQL din�mico para crear el usuario y asignar el rol
        EXEC sp_executesql @SqlUsuario;
    END
    ELSE
    BEGIN
        PRINT 'La base de datos Com5600G12 no existe';
    END
END;
GO





EXEC Autenticacion.CrearRolesConPermisos
EXEC Autenticacion.CrearLoginUser 'soyYO','contrase�a'


USE MASTER
CREATE LOGIN BDLOCO
WITH PASSWORD ='SANLORENZO'

USE Com5600G12 
CREATE USER LOCOLOCOs FOR LOGIN BDLOCO