USE Com5600G12;
GO

CREATE OR ALTER PROCEDURE Supermercado.InsertarProductosCatalogo
    @rutaArchivo NVARCHAR(MAX)
AS
BEGIN
    -- Manejo de errores
    BEGIN TRY
        -- Crear una tabla TEMPORAL para almacenar los datos del archivo CSV
        CREATE TABLE #temporal (
            id NVARCHAR(MAX),                -- ID del producto
            category NVARCHAR(MAX) NOT NULL, -- Categoría del producto
            name NVARCHAR(MAX) NOT NULL,     -- Nombre del producto
            price NVARCHAR(MAX) NOT NULL,    -- Precio unitario (cargado como NVARCHAR para manejar errores)
            reference_price NVARCHAR(MAX) NOT NULL, -- Precio de referencia (cargado como NVARCHAR)
            reference_unit NVARCHAR(100) NOT NULL,  -- Unidad de referencia
            date NVARCHAR(MAX) NOT NULL       -- Fecha (cargado como NVARCHAR para manejar errores)
        );

        -- Construir el comando BULK INSERT de forma dinámica
        DECLARE @sql NVARCHAR(MAX) = N'
            BULK INSERT #temporal
            FROM ''' + @rutaArchivo + '''
            WITH (
                FORMAT = ''CSV'',
                CODEPAGE = ''1200'', -- UTF-16 LE
                FIRSTROW = 2,
                FIELDTERMINATOR = '','',
                ROWTERMINATOR = ''0x0A'',
                FIELDQUOTE = ''"'' 
            );
        ';

        -- Ejecutar el BULK INSERT de manera dinámica
        EXEC sp_executesql @sql;

        -- Insertar los datos únicos en la tabla definitiva Supermercado.Producto
        INSERT INTO Supermercado.Producto (Categoria, NombreProducto, PrecioUnitario, PrecioReferencia, UnidadReferencia, Fecha)
        SELECT 
            category AS Categoria,
            -- Aquí reemplazamos '?' por 'ñ' en la columna name (NombreProducto)
            REPLACE(name, N'?', N'ñ') AS NombreProducto,
            TRY_CAST(price AS DECIMAL(10, 2)) AS PrecioUnitario,
            TRY_CAST(reference_price AS DECIMAL(10, 2)) AS PrecioReferencia,
            reference_unit AS UnidadReferencia,
            TRY_CAST(date AS DATETIME) AS Fecha
        FROM (
            SELECT 
                category,
                name,
                price,
                reference_price,
                reference_unit,
                date,
                ROW_NUMBER() OVER (PARTITION BY name ORDER BY TRIM(LOWER(category))) AS RowNum
            FROM #temporal
            WHERE 
                TRY_CAST(price AS DECIMAL(10, 2)) IS NOT NULL AND
                TRY_CAST(reference_price AS DECIMAL(10, 2)) IS NOT NULL AND
                TRY_CAST(date AS DATETIME) IS NOT NULL
        ) AS subquery
        WHERE RowNum = 1 AND 
        NOT EXISTS (
            SELECT 1
            FROM Supermercado.Producto p
            WHERE p.NombreProducto = subquery.name
        );

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




CREATE OR ALTER PROCEDURE Supermercado.InsertarProductosElectronicos
    @rutaArchivo NVARCHAR(MAX)
AS
BEGIN
    -- Manejo de errores
    BEGIN TRY
        -- Crear una tabla TEMPORAL para almacenar los datos del archivo Excel
		DECLARE @tipoCambio DECIMAL(10, 4);

		EXEC Services.ObtenerTipoCambioUsdToArs @tipoCambio OUTPUT;

        CREATE TABLE #temporal (
            Product NVARCHAR(MAX) NOT NULL,       -- Nombre del producto
            PrecioEnDolares NVARCHAR(MAX) NOT NULL -- Precio unitario (como NVARCHAR para manejar errores)
        );

        -- Construir el comando de inserción usando OPENROWSET de forma dinámica
		DECLARE @sql NVARCHAR(MAX) = '
			INSERT INTO #temporal
			SELECT *
			FROM OPENROWSET(
				''Microsoft.ACE.OLEDB.12.0'', 
				''Excel 12.0 Xml;HDR=YES;Database=' + @rutaArchivo + ''', 
				''SELECT * FROM [Sheet1$]''
			) AS ExcelData;
		';

        -- Ejecutar la consulta dinámica
        EXEC sp_executesql @sql;

        -- Insertar los datos únicos en la tabla definitiva Supermercado.Producto
        INSERT INTO Supermercado.Producto (Categoria, NombreProducto,PrecioUnitario, PrecioUnitarioUsd, Fecha)
        SELECT 
            'Electronicos' AS Categoria,
            Product AS NombreProducto,
			TRY_CAST(PrecioEnDolares AS DECIMAL(10, 2)) * @tipoCambio AS PrecioUnitario,
            TRY_CAST(PrecioEnDolares AS DECIMAL(10, 2)) AS PrecioUnitarioUsd,
            GETDATE() AS Fecha
        FROM (
            SELECT 
                Product,
                PrecioEnDolares,
                ROW_NUMBER() OVER (PARTITION BY Product ORDER BY PrecioEnDolares) AS RowNum
            FROM #temporal
        ) AS subquery
        WHERE RowNum = 1 AND 
		NOT EXISTS (
			SELECT 1
			FROM Supermercado.Producto p
			WHERE p.NombreProducto = subquery.Product
		);

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

CREATE OR ALTER PROCEDURE Supermercado.InsertarProductosImportados
    @rutaArchivo NVARCHAR(MAX)
AS
BEGIN
    -- Manejo de errores
    BEGIN TRY
        -- Crear una tabla TEMPORAL para almacenar los datos del archivo Excel
        CREATE TABLE #temporal (
			IdProducto NVARCHAR(MAX) NOT NULL,
            NombreProducto NVARCHAR(MAX) NOT NULL,
            Proveedor NVARCHAR(MAX) NOT NULL,
			Categoria NVARCHAR(MAX) NOT NULL,
			CantidadPorUnidad NVARCHAR(MAX) NOT NULL,
			PrecioUnidad NVARCHAR(MAX) NOT NULL
        );

        -- Construir el comando de inserción usando OPENROWSET de forma dinámica
		DECLARE @sql NVARCHAR(MAX) = '
			INSERT INTO #temporal
			SELECT *
			FROM OPENROWSET(
				''Microsoft.ACE.OLEDB.12.0'', 
				''Excel 12.0 Xml;HDR=YES;Database=' + @rutaArchivo + ''', 
				''SELECT * FROM [Listado de Productos$]''
			) AS ExcelData;
		';

        -- Ejecutar la consulta dinámica
        EXEC sp_executesql @sql;

        -- Insertar los datos únicos en la tabla definitiva Supermercado.Producto
        INSERT INTO Supermercado.Producto (NombreProducto,UnidadReferencia,Categoria,Proveedor,PrecioUnitario, Fecha)
        SELECT  
			NombreProducto,
			CantidadPorUnidad AS UnidadReferencia,
			Categoria,
			Proveedor,
            TRY_CAST(PrecioUnidad AS DECIMAL(10, 2)) AS PrecioUnitario,
            GETDATE() AS Fecha
        FROM (
            SELECT 
                NombreProducto,
                PrecioUnidad,
				Proveedor,
				Categoria,
				CantidadPorUnidad,
                ROW_NUMBER() OVER (PARTITION BY NombreProducto ORDER BY IdProducto) AS RowNum
            FROM #temporal
        ) AS subquery
        WHERE RowNum = 1 AND 
		NOT EXISTS (
			SELECT 1
			FROM Supermercado.Producto p
			WHERE p.NombreProducto = subquery.NombreProducto
		);

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


EXEC Supermercado.InsertarProductosCatalogo 'C:\Users\marti\Desktop\BBDD Ap\TrabajoIntegradorG12\Productos\catalogo.csv'
GO

EXEC Supermercado.InsertarProductosElectronicos 'C:\Users\marti\Desktop\BBDD Ap\TrabajoIntegradorG12\Productos\Electronic accessories.xlsx'
GO

EXEC Supermercado.InsertarProductosImportados'C:\Users\marti\Desktop\BBDD Ap\TrabajoIntegradorG12\Productos\Productos_importados.xlsx'
GO

SELECT * FROM Supermercado.Producto


