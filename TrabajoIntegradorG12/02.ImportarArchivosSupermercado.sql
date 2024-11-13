USE Com5600G12;
GO

CREATE OR ALTER PROCEDURE Supermercado.InsertarSucursales
    @rutaArchivo NVARCHAR(MAX)
AS
BEGIN
    -- Manejo de errores
    BEGIN TRY
        -- Crear una tabla TEMPORAL para almacenar los datos del archivo Excel
        CREATE TABLE #temporal (
			Ciudad NVARCHAR(MAX) NOT NULL,
            ReemplazoCiudad NVARCHAR(MAX) NOT NULL,
            direccion NVARCHAR(MAX) NOT NULL,
			horario NVARCHAR(MAX) NOT NULL,
			telefono NVARCHAR(MAX) NOT NULL
        );

        -- Construir el comando de inserción usando OPENROWSET de forma dinámica
		DECLARE @sql NVARCHAR(MAX) = '
			INSERT INTO #temporal
			SELECT *
			FROM OPENROWSET(
				''Microsoft.ACE.OLEDB.12.0'', 
				''Excel 12.0 Xml;HDR=YES;Database=' + @rutaArchivo + ''', 
				''SELECT * FROM [sucursal$]''
			) AS ExcelData;
		';

        -- Ejecutar la consulta dinámica
        EXEC sp_executesql @sql;

        -- Insertar los datos únicos en la tabla definitiva Supermercado.Producto
        INSERT INTO Supermercado.Sucursal (Ciudad,Direccion,Horario,Telefono)
        SELECT  
			ReemplazoCiudad as Ciudad,
			direccion AS Direccion,
			horario AS horario,
            telefono AS Telefono
        FROM (
            SELECT 
                ReemplazoCiudad,
                direccion,
				horario,
				telefono,
                ROW_NUMBER() OVER (PARTITION BY direccion ORDER BY ReemplazoCiudad) AS RowNum
            FROM #temporal
        ) AS subquery
        WHERE RowNum = 1

        -- Limpiar la tabla temporal
        DROP TABLE #temporal;

    END TRY
    BEGIN CATCH
        -- Si ocurre un error, muestra el mensaje de error
        PRINT 'Error al insertar los datos en la tabla Supermercado.Producto:';
        PRINT ERROR_MESSAGE();
        
        -- Asegúrate de limpiar la tabla temporal en caso de error
        IF OBJECT_ID('tempdb..#temporal') IS NOT NULL
            DROP TABLE #temporal;
    END CATCH;
END;
GO

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER PROCEDURE Supermercado.InsertarEmpleados --solo el admin por logica
    @rutaArchivo NVARCHAR(MAX)
AS
BEGIN
    -- Manejo de errores
    BEGIN TRY
        -- Crear una tabla temporal para almacenar los datos del archivo Excel
        CREATE TABLE #temporal (
            Legajo INT,
            Nombre NVARCHAR(100),
            Apellido NVARCHAR(100),
            DNI INT,
            Direccion NVARCHAR(200),
            Email NVARCHAR(100),
            EmailEmpresa NVARCHAR(100),
            Cargo NVARCHAR(50),
            Sucursal NVARCHAR(50),
            Turno NVARCHAR(30)
        );

        -- Declarar la consulta para cargar los datos desde el archivo Excel
        DECLARE @sql NVARCHAR(MAX) = '
            INSERT INTO #temporal (Legajo, Nombre, Apellido, DNI, Direccion, Email, EmailEmpresa, Cargo, Sucursal, Turno)
            SELECT 
                F1 AS Legajo,
                F2 AS Nombre,
                F3 AS Apellido,
                F4 AS DNI,
                F5 AS Direccion,
                F6 AS Email,
                F7 AS EmailEmpresa,
                F9 AS Cargo,
                F10 AS Sucursal,
                F11 AS Turno
            FROM OPENROWSET(
                ''Microsoft.ACE.OLEDB.12.0'', 
                ''Excel 12.0 Xml;HDR=NO;Database=' + @rutaArchivo + ''', 
                ''SELECT * FROM [Empleados$]''
            ) AS ExcelData
            WHERE F4 IS NOT NULL'; -- Filtrar filas donde DNI no sea NULL

        EXEC sp_executesql @sql;

        -- Inserción en Supermercado.Empleado
        INSERT INTO Supermercado.Empleado (Legajo, Nombre, Apellido, Dni, Direccion, Email, EmailEmpresa, cargo, SucursalID, Turno)
        SELECT  
            t.Legajo,
            t.Nombre,
            t.Apellido,
            t.DNI,
            t.Direccion,
            t.Email,
            t.EmailEmpresa,
            t.Cargo,
            s.SucursalID,
            t.Turno
        FROM 
            #temporal t
        JOIN 
            Supermercado.Sucursal s ON t.Sucursal = s.Ciudad;

        -- Limpiar la tabla temporal al final
        DROP TABLE #temporal;

    END TRY
    BEGIN CATCH
        -- Si ocurre un error, muestra el mensaje de error
        PRINT 'Error al insertar los datos en la tabla Supermercado.Empleado:';
        PRINT ERROR_MESSAGE();
        
        -- Asegúrate de limpiar la tabla temporal en caso de error
        IF OBJECT_ID('tempdb..#temporal') IS NOT NULL
            DROP TABLE #temporal;
    END CATCH;
END;
GO

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

CREATE OR ALTER PROCEDURE Supermercado.InsertarEmpleadosEncriptado --solo el admin por logica
    @rutaArchivo NVARCHAR(MAX),
    @fraseClave NVARCHAR(128)
AS
BEGIN
    -- Manejo de errores
    BEGIN TRY
        -- Crear una tabla temporal para almacenar los datos del archivo Excel
        CREATE TABLE #temporal (
            Legajo INT,
            Nombre NVARCHAR(100),
            Apellido NVARCHAR(100),
            DNI INT,
            Direccion NVARCHAR(200),
            Email NVARCHAR(100),
            EmailEmpresa NVARCHAR(100),
            Cargo NVARCHAR(50),
            Sucursal NVARCHAR(50),
            Turno NVARCHAR(30)
        );

        -- Declarar la consulta para cargar los datos desde el archivo Excel
        DECLARE @sql NVARCHAR(MAX) = '
            INSERT INTO #temporal (Legajo, Nombre, Apellido, DNI, Direccion, Email, EmailEmpresa, Cargo, Sucursal, Turno)
            SELECT 
                F1 AS Legajo,
                F2 AS Nombre,
                F3 AS Apellido,
                F4 AS DNI,
                F5 AS Direccion,
                F6 AS Email,
                F7 AS EmailEmpresa,
                F9 AS Cargo,
                F10 AS Sucursal,
                F11 AS Turno
            FROM OPENROWSET(
                ''Microsoft.ACE.OLEDB.12.0'', 
                ''Excel 12.0 Xml;HDR=NO;Database=' + @rutaArchivo + ''', 
                ''SELECT * FROM [Empleados$]''
            ) AS ExcelData
            WHERE F4 IS NOT NULL'; -- Filtrar filas donde DNI no sea NULL

        EXEC sp_executesql @sql;

        -- Inserción en Supermercado.EmpleadoEncriptado con encriptación
        INSERT INTO Supermercado.EmpleadoEncriptado (
            Legajo,
            Nombre,
            Apellido,
            Dni,
            Direccion,
            Email,
            EmailEmpresa,
            Cargo,
            SucursalID,
            Turno
        )
        SELECT  
            t.Legajo,
            EncryptByPassPhrase(@fraseClave, t.Nombre),         -- Encriptar Nombre
            EncryptByPassPhrase(@fraseClave, t.Apellido),       -- Encriptar Apellido
            EncryptByPassPhrase(@fraseClave, CAST(t.DNI AS NVARCHAR)),  -- Encriptar DNI
            EncryptByPassPhrase(@fraseClave, t.Direccion),      -- Encriptar Direccion
            EncryptByPassPhrase(@fraseClave, t.Email),          -- Encriptar Email
            t.EmailEmpresa,                                     -- No encriptamos EmailEmpresa
            t.Cargo,                                            -- No encriptamos Cargo
            s.SucursalID,
            t.Turno
        FROM 
            #temporal t
        JOIN 
            Supermercado.Sucursal s ON t.Sucursal = s.Ciudad;

        -- Limpiar la tabla temporal al final
        DROP TABLE #temporal;

    END TRY
    BEGIN CATCH
        -- Si ocurre un error, muestra el mensaje de error
        PRINT 'Error al insertar los datos en la tabla Supermercado.EmpleadoEncriptado:';
        PRINT ERROR_MESSAGE();
        
        -- Asegúrate de limpiar la tabla temporal en caso de error
        IF OBJECT_ID('tempdb..#temporal') IS NOT NULL
            DROP TABLE #temporal;
    END CATCH;
END;
GO

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


CREATE OR ALTER PROCEDURE Ventas.InsertarMediosPago
    @rutaArchivo NVARCHAR(MAX)
AS
BEGIN
    -- Manejo de errores
    BEGIN TRY
        -- Crear una tabla temporal para almacenar los datos del archivo Excel
        CREATE TABLE #temporal (
            Descripcion NVARCHAR(255),
            MedioPagoName NVARCHAR(50)
        );

        -- Declarar la consulta para cargar los datos desde el archivo Excel
        DECLARE @sql NVARCHAR(MAX) = '
            INSERT INTO #temporal (Descripcion, MedioPagoName)
            SELECT 
                F1 AS Descripcion,
                F2 AS MedioPagoName
            FROM OPENROWSET(
                ''Microsoft.ACE.OLEDB.12.0'', 
                ''Excel 12.0 Xml;HDR=YES;Database=' + @rutaArchivo + ''', 
                ''SELECT * FROM [medios de pago$B3:C]''  -- Aquí se ajusta el rango
            ) AS ExcelData';

        -- Ejecutar la consulta dinámica para cargar los datos del Excel en la tabla temporal
        EXEC sp_executesql @sql;

        -- Insertar los datos de la tabla temporal en la tabla principal Ventas.MediosPago
        INSERT INTO Ventas.MediosPago (MedioPagoName, Descripcion)
        SELECT MedioPagoName, Descripcion
        FROM #temporal;

        -- Limpiar la tabla temporal al final
        DROP TABLE #temporal;

    END TRY
    BEGIN CATCH
        -- Si ocurre un error, muestra el mensaje de error
        PRINT 'Error al insertar los datos en la tabla Ventas.MediosPago:';
        PRINT ERROR_MESSAGE();
        
        -- Asegúrate de limpiar la tabla temporal en caso de error
        IF OBJECT_ID('tempdb..#temporal') IS NOT NULL
            DROP TABLE #temporal;
    END CATCH;
END;
GO


exec Supermercado.InsertarSucursales 'C:\Users\marin\Desktop\BBDD\BaseDeDatosG12\Informacion_complementaria.xlsx'
exec Supermercado.InsertarEmpleados 'C:\Users\marin\Desktop\BBDD\BaseDeDatosG12\Informacion_complementaria.xlsx'
exec Ventas.InsertarMediosPago 'C:\Users\marin\Desktop\BBDD\BaseDeDatosG12\Informacion_complementaria.xlsx'
