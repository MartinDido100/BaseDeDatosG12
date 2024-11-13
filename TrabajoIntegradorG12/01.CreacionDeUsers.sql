---------------------------ADMIN------------------------------------------------------------------------
-- 1. Crear el login para el servidor
CREATE LOGIN fabricio WITH PASSWORD = 'basededatos';

-- 2. Cambiar al contexto de la base de datos COMERCIO
USE COMERCIO;

-- 3. Crear el usuario en la base de datos 'COMERCIO' asociando el login 'fabricio'
CREATE USER fabricio FOR LOGIN fabricio;

-- 4. Asignar el rol 'sysadmin' al usuario 'fabricio' (permiso completo)
ALTER SERVER ROLE sysadmin ADD MEMBER fabricio;

-- Confirmación de la creación
PRINT 'El usuario fabricio ha sido creado con permisos de administrador';
-----------------------------------SUPERVISOR------------------------------------------------------------
-- Crear login para 'martin'
CREATE LOGIN martin WITH PASSWORD = 'tincho32';

-- Usar la base de datos 'COMERCIO'
USE COMERCIO;

-- Crear el usuario 'martin' en la base de datos 'COMERCIO'
CREATE USER martin FOR LOGIN martin;

-- Asignar el rol 'Supervisor' al usuario 'martin'
EXEC sp_addrolemember 'Supervisor', 'martin';

PRINT 'Usuario "martin" creado exitosamente con el rol Supervisor.';
--------------------------------------------------------------------------------



CREATE OR ALTER PROCEDURE CrearRolesConPermisos --CREO LOS ROLES EXISTENTES EN MI BD
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

CREATE OR ALTER PROCEDURE CrearLogin
    @LoginNombre NVARCHAR(100),
    @Contraseña NVARCHAR(100)
AS
BEGIN
    -- Verificar si el login ya existe
    IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = @LoginNombre)
    BEGIN
        -- Crear un nuevo login usando SQL dinámico
        DECLARE @Sql NVARCHAR(MAX);
        
        -- Construir la cadena SQL dinámica correctamente
        SET @Sql = 'CREATE LOGIN ' + QUOTENAME(@LoginNombre) + ' WITH PASSWORD = ''' + @Contraseña + '''';  -- Doble comilla simple para enmarcar la contraseña

        -- Ejecutar la consulta dinámica
        EXEC sp_executesql @Sql;
        
        PRINT 'Login creado exitosamente';
    END
    ELSE
    BEGIN
        PRINT 'El login ya existe';
    END
END;
GO





CREATE OR ALTER PROCEDURE CrearUsuario  -- cualquier rol
    @LoginNombre NVARCHAR(100),
    @UsuarioNombre NVARCHAR(100)
AS
BEGIN
    -- Verificar si el login existe
    IF EXISTS (SELECT * FROM sys.server_principals WHERE name = @LoginNombre)
    BEGIN
        -- Verificar si la base de datos 'COMERCIO' existe
        IF EXISTS (SELECT * FROM sys.databases WHERE name = 'COMERCIO')
        BEGIN
        
            -- Verificar si el usuario ya existe en la base de datos 'COMERCIO'
            IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @UsuarioNombre)
            BEGIN
                PRINT 'El usuario ya existe en la base de datos COMERCIO';
            END
            ELSE
            BEGIN
                -- Crear el usuario en la base de datos 'COMERCIO' usando SQL dinámico
                DECLARE @Sql NVARCHAR(MAX);
                SET @Sql = 'CREATE USER ' + QUOTENAME(@UsuarioNombre) + ' FOR LOGIN ' + QUOTENAME(@LoginNombre) + ';
                            PRINT ''Usuario creado exitosamente en la base de datos COMERCIO'';
                            
                            -- Asignar el rol ''Empleado'' automáticamente
                            EXEC sp_addrolemember @RoleName = N''Empleado'', @MemberName = N''' + @UsuarioNombre + '''; 
                            PRINT ''Rol Empleado asignado exitosamente a ' + @UsuarioNombre + ''';';
                
                -- Ejecutar el SQL dinámico
                EXEC sp_executesql @Sql;
            END
        END
        ELSE
        BEGIN
            PRINT 'La base de datos COMERCIO no existe';
        END
    END
    ELSE
    BEGIN
        PRINT 'El login especificado no existe';
    END
END;
GO





EXEC CrearRolesConPermisos
EXEC CrearLogin 'ingenieria','informatica'
EXEC CrearUsuario 'ingenieria','ahorasinene'