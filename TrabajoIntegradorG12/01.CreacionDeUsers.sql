-- Script para crear roles y usuarios para la base de datos

---------------------------ADMIN------------------------------------------------------------------------
-- 1. Crear el login para el servidor
CREATE LOGIN messi WITH PASSWORD = 'basededatos';

-- 2. Cambiar al contexto de la base de datos Com5600G12
USE Com5600G12;

-- 3. Crear el usuario en la base de datos 'Com5600G12' asociando el login 'fabricio'
CREATE USER mateo FOR LOGIN messi;

-- 4. Asignar el rol 'sysadmin' al usuario 'fabricio' (permiso completo)
ALTER SERVER ROLE sysadmin ADD MEMBER fabricio;
--------------------------------------------------------------------------------


USE Com5600G12
GO


CREATE OR ALTER PROCEDURE Supervisor.CrearRolesConPermisos --CREO LOS ROLES EXISTENTES EN MI BD
AS
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Supervisor')
    BEGIN
        CREATE ROLE Supervisor;
        PRINT 'Rol Supervisor creado';
        
        GRANT EXECUTE ON SCHEMA::Ventas TO Supervisor;
        GRANT EXECUTE ON SCHEMA::Supermercado TO Supervisor;
		GRANT EXECUTE ON SCHEMA::Supervisor TO Supervisor;
        PRINT 'Permisos totales asignados al rol Supervisor';
    END
    ELSE
    BEGIN
        PRINT 'El rol Supervisor ya existe';
    END

    IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Empleado')
    BEGIN
        CREATE ROLE Empleado;
        PRINT 'Rol Empleado creado';
        
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

CREATE OR ALTER PROCEDURE Supermercado.CrearLoginUserEmpleado
    @LoginUsuario NVARCHAR(100),
    @Contraseña NVARCHAR(100)
AS
BEGIN
    IF EXISTS (SELECT * FROM sys.server_principals WHERE name = @LoginUsuario)
    BEGIN
        RAISERROR('Error: El login ya existe', 16, 1);
        RETURN;
    END

    DECLARE @SqlLogin NVARCHAR(MAX);
    SET @SqlLogin = 'CREATE LOGIN ' + QUOTENAME(@LoginUsuario) + ' WITH PASSWORD = ''' + @Contraseña + '''';
    EXEC sp_executesql @SqlLogin;
    PRINT 'Login creado exitosamente';

    IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Com5600G12')
    BEGIN
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
        
        EXEC sp_executesql @SqlUsuario;
    END
    ELSE
    BEGIN
        PRINT 'La base de datos Com5600G12 no existe';
    END
END;
GO

--POR SI UN SUPERVISOR QUIERE AGREGAR A OTRO SUPERVISOR
CREATE OR ALTER PROCEDURE Supervisor.CrearLoginUserSupervisor
    @LoginUsuario NVARCHAR(100),
    @Contraseña NVARCHAR(100)
AS
BEGIN
    IF EXISTS (SELECT * FROM sys.server_principals WHERE name = @LoginUsuario)
    BEGIN
        RAISERROR('Error: El login ya existe', 16, 1);
        RETURN;
    END

    DECLARE @SqlLogin NVARCHAR(MAX);
    SET @SqlLogin = 'CREATE LOGIN ' + QUOTENAME(@LoginUsuario) + ' WITH PASSWORD = ''' + @Contraseña + '''';
    EXEC sp_executesql @SqlLogin;
    PRINT 'Login creado exitosamente';

    IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Com5600G12')
    BEGIN
        DECLARE @SqlUsuario NVARCHAR(MAX);
        
        SET @SqlUsuario = '
            USE Com5600G12;
            IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N''' + @LoginUsuario + ''')
            BEGIN
                CREATE USER ' + QUOTENAME(@LoginUsuario) + ' FOR LOGIN ' + QUOTENAME(@LoginUsuario) + ';
                PRINT ''Usuario creado exitosamente en la base de datos Com5600G12'';

                -- Asignar el rol ''Empleado'' autom�ticamente
                EXEC sp_addrolemember @RoleName = N''Supervisor'', @MemberName = N''' + @LoginUsuario + ''';
                PRINT ''Rol Supervisor asignado exitosamente a ' + @LoginUsuario + ''';
            END
            ELSE
            BEGIN
                PRINT ''El usuario ya existe en la base de datos Com5600G12'';
            END';
        
        EXEC sp_executesql @SqlUsuario;
    END
    ELSE
    BEGIN
        PRINT 'La base de datos Com5600G12 no existe';
    END
END;
GO

