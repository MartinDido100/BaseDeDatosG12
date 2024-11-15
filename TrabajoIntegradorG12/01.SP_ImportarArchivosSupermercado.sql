-- Script para crear los procedures que importan datos del supermercado desde los maestros
-- como sucursales, empleados, etc...

USE Com5600G12;
GO

CREATE OR ALTER PROCEDURE Supermercado.InsertarSucursales
    @rutaArchivo NVARCHAR(MAX)
AS
BEGIN
    BEGIN TRY
        CREATE TABLE #temporal (
			Ciudad NVARCHAR(MAX) NOT NULL,
            ReemplazoCiudad NVARCHAR(MAX) NOT NULL,
            direccion NVARCHAR(MAX) NOT NULL,
			horario NVARCHAR(MAX) NOT NULL,
			telefono NVARCHAR(MAX) NOT NULL
        );

		DECLARE @sql NVARCHAR(MAX) = '
			INSERT INTO #temporal
			SELECT *
			FROM OPENROWSET(
				''Microsoft.ACE.OLEDB.12.0'', 
				''Excel 12.0 Xml;HDR=YES;Database=' + @rutaArchivo + ''', 
				''SELECT * FROM [sucursal$]''
			) AS ExcelData;
		';

        EXEC sp_executesql @sql;

        INSERT INTO Supermercado.Sucursal (Ciudad,Direccion,Horario,Telefono,CiudadFake)
        SELECT  
			ReemplazoCiudad as Ciudad,
			direccion AS Direccion,
			horario AS horario,
            telefono AS Telefono,
			Ciudad AS CiudadFake
        FROM (
            SELECT 
                ReemplazoCiudad,
				Ciudad,
                direccion,
				horario,
				telefono,
                ROW_NUMBER() OVER (PARTITION BY direccion ORDER BY ReemplazoCiudad) AS RowNum
            FROM #temporal
        ) AS subquery
        WHERE RowNum = 1 AND 
		NOT EXISTS (
                SELECT 1 
                FROM Supermercado.Sucursal s
                WHERE s.Direccion = subquery.direccion
        );

        DROP TABLE #temporal;

    END TRY
    BEGIN CATCH
        PRINT 'Error al insertar los datos en la tabla Supermercado.Producto:';
        PRINT ERROR_MESSAGE();
        
        IF OBJECT_ID('tempdb..#temporal') IS NOT NULL
            DROP TABLE #temporal;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Supermercado.InsertarCategorias
    @rutaArchivo NVARCHAR(MAX)
AS
BEGIN
    BEGIN TRY

		IF NOT EXISTS(SELECT 1 FROM Supermercado.Categoria WHERE Descripcion LIKE 'Electronicos')
		BEGIN
			INSERT INTO Supermercado.Categoria(Descripcion) VALUES ('Electronicos');
		END

        CREATE TABLE #temporal (
			LineaProducto NVARCHAR(MAX) NOT NULL,
            Descripcion NVARCHAR(MAX) NOT NULL,
        );

		DECLARE @sql NVARCHAR(MAX) = '
			INSERT INTO #temporal
			SELECT *
			FROM OPENROWSET(
				''Microsoft.ACE.OLEDB.12.0'', 
				''Excel 12.0 Xml;HDR=YES;Database=' + @rutaArchivo + ''', 
				''SELECT * FROM [Clasificacion productos$]''
			) AS ExcelData;
		';

        EXEC sp_executesql @sql;

        INSERT INTO Supermercado.Categoria (Descripcion)
        SELECT  
			Descripcion as Descripcion,
        FROM (
            SELECT 
                Descripcion,
                ROW_NUMBER() OVER (PARTITION BY direccion ORDER BY ReemplazoCiudad) AS RowNum
            FROM #temporal
        ) AS subquery
        WHERE RowNum = 1 AND 
		NOT EXISTS (
                SELECT 1 
                FROM Supermercado.Categoria c
                WHERE c.Descripcion = subquery.Descripcion
        );

        DROP TABLE #temporal;

    END TRY
    BEGIN CATCH
        PRINT 'Error al insertar los datos en la tabla Supermercado.Producto:';
        PRINT ERROR_MESSAGE();
        
        IF OBJECT_ID('tempdb..#temporal') IS NOT NULL
            DROP TABLE #temporal;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Supermercado.InsertarEmpleados --solo el admin por logica
    @rutaArchivo NVARCHAR(MAX)
AS
BEGIN
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

        INSERT INTO Supermercado.Empleado (Legajo, Nombre, Apellido, DNI, Direccion, Email, EmailEmpresa, Cargo, SucursalID, Turno)
        SELECT  
            subquery.Legajo,
            subquery.Nombre,
            subquery.Apellido,
            subquery.DNI,
            subquery.Direccion,
            subquery.Email,
            subquery.EmailEmpresa,
            subquery.Cargo,
            s.SucursalID,
            subquery.Turno
        FROM (
            SELECT 
                *,
                ROW_NUMBER() OVER (PARTITION BY Direccion ORDER BY Sucursal) AS RowNum
            FROM #temporal
        ) AS subquery
        JOIN 
            Supermercado.Sucursal s ON subquery.Sucursal = s.Ciudad
        WHERE 
            subquery.RowNum = 1 -- Solo toma la primera ocurrencia por Dirección
            AND NOT EXISTS (
                SELECT 1 
                FROM Supermercado.Empleado e 
                WHERE e.Legajo = subquery.Legajo
            );

        DROP TABLE #temporal;

    END TRY
    BEGIN CATCH
        PRINT 'Error al insertar los datos en la tabla Supermercado.Empleado:';
        PRINT ERROR_MESSAGE();
        
        IF OBJECT_ID('tempdb..#temporal') IS NOT NULL
            DROP TABLE #temporal;
    END CATCH;
END;
GO


CREATE OR ALTER PROCEDURE Ventas.InsertarMediosPago
    @rutaArchivo NVARCHAR(MAX)
AS
BEGIN
    -- Manejo de errores
    BEGIN TRY
        CREATE TABLE #temporal (
            Descripcion NVARCHAR(255),
            MedioPagoName NVARCHAR(50)
        );

        DECLARE @sql NVARCHAR(MAX) = '
            INSERT INTO #temporal (Descripcion, MedioPagoName)
            SELECT 
                F1 AS Descripcion,
                F2 AS MedioPagoName
            FROM OPENROWSET(
                ''Microsoft.ACE.OLEDB.12.0'', 
                ''Excel 12.0 Xml;HDR=NO;Database=' + @rutaArchivo + ''', 
                ''SELECT * FROM [medios de pago$B3:C]''  -- Aquí se ajusta el rango
            ) AS ExcelData';

        EXEC sp_executesql @sql;

        INSERT INTO Ventas.MediosPago (MedioPagoName, Descripcion)
        SELECT MedioPagoName, Descripcion
        FROM #temporal
		WHERE NOT EXISTS (
            SELECT 1
            FROM Ventas.MediosPago
            WHERE Ventas.MediosPago.MedioPagoName = #temporal.MedioPagoName
        );

        DROP TABLE #temporal;

    END TRY
    BEGIN CATCH
        PRINT 'Error al insertar los datos en la tabla Ventas.MediosPago:';
        PRINT ERROR_MESSAGE();
        
        IF OBJECT_ID('tempdb..#temporal') IS NOT NULL
            DROP TABLE #temporal;
    END CATCH;
END;
GO