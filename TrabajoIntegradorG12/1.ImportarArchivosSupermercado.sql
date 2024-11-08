USE Comercio;
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
			Ciudad as ReemplazoCiudad,
			Direccion AS direccion,
			Horario AS horario,
            Telefono AS telefono
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
			Ciudad as ReemplazoCiudad,
			Direccion AS direccion,
			Horario AS horario,
            Telefono AS telefono
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