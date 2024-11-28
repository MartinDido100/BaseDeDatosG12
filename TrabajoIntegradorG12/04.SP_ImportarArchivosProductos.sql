-- Script que crea los procedures para importar los archivos con productos
-- Ejecutar en el orden que se desarrollan

USE Com5600G12;
GO


CREATE OR ALTER PROCEDURE Supermercado.InsertarProductosCatalogo
    @rutaArchivo NVARCHAR(MAX)
AS
BEGIN
    BEGIN TRY
        -- Crear la tabla temporal para cargar el archivo
        CREATE TABLE #temporal (
            id NVARCHAR(MAX),              
            category NVARCHAR(MAX) NOT NULL, 
            name NVARCHAR(MAX) NOT NULL,    
            price NVARCHAR(MAX) NOT NULL,   
            reference_price NVARCHAR(MAX) NOT NULL, 
            reference_unit NVARCHAR(100) NOT NULL, 
            date NVARCHAR(MAX) NOT NULL    
        );

        -- Insertar datos desde el archivo CSV
        DECLARE @sql NVARCHAR(MAX) = N'
            BULK INSERT #temporal
            FROM ''' + @rutaArchivo + '''
            WITH (
                FORMAT = ''CSV'',
                CODEPAGE = ''65001'',
                FIRSTROW = 2,
                FIELDTERMINATOR = '','',
                ROWTERMINATOR = ''0x0A'',
                FIELDQUOTE = ''"'' 
            );
        ';

        EXEC sp_executesql @sql;

        INSERT INTO Supermercado.Categoria (Descripcion)
        SELECT DISTINCT category
        FROM #temporal
        WHERE NOT EXISTS (
            SELECT 1
            FROM Supermercado.Categoria c
            WHERE c.Descripcion = #temporal.category
        );

        -- Insertar productos en la tabla Supermercado.Producto
        INSERT INTO Supermercado.Producto (CategoriaID, NombreProducto, PrecioUnitario, PrecioReferencia, UnidadReferencia, Fecha)
        SELECT
            (SELECT ID FROM Supermercado.Categoria WHERE Descripcion = t.category) AS CategoriaID,
            t.name AS NombreProducto,
            TRY_CAST(t.price AS DECIMAL(10, 2)) AS PrecioUnitario,
            TRY_CAST(t.reference_price AS DECIMAL(10, 2)) AS PrecioReferencia,
            t.reference_unit AS UnidadReferencia,
            t.date AS Fecha
        FROM (
            SELECT 
                category,
                name,
                price,
                reference_price,
                reference_unit,
                date,
                ROW_NUMBER() OVER (PARTITION BY name ORDER BY category) AS RowNum
            FROM #temporal
            WHERE 
                TRY_CAST(price AS DECIMAL(10, 2)) IS NOT NULL AND
                TRY_CAST(reference_price AS DECIMAL(10, 2)) IS NOT NULL AND
                TRY_CAST(date AS DATETIME) IS NOT NULL
        ) AS t
        WHERE t.RowNum = 1 AND 
        NOT EXISTS (
            SELECT 1
            FROM Supermercado.Producto p
            WHERE p.NombreProducto = t.name
        );

        -- Eliminar la tabla temporal
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



CREATE OR ALTER PROCEDURE Supermercado.InsertarProductosElectronicos
    @rutaArchivo NVARCHAR(MAX)
AS
BEGIN
    BEGIN TRY
        -- Verificar si la categoría "Electrónicos" existe y obtener su ID
        DECLARE @CategoriaID INT;

        IF NOT EXISTS (SELECT 1 FROM Supermercado.Categoria WHERE Descripcion = 'Electronicos')
        BEGIN
            INSERT INTO Supermercado.Categoria (Descripcion)
            VALUES ('Electronicos');
        END

        SELECT @CategoriaID = ID
        FROM Supermercado.Categoria
        WHERE Descripcion = 'Electronicos';

        -- Declarar la variable para el tipo de cambio
        DECLARE @tipoCambio DECIMAL(10, 4);

        EXEC Services.ObtenerTipoCambioUsdToArs @tipoCambio OUTPUT;

        -- Crear la tabla temporal
        CREATE TABLE #temporal (
            Product NVARCHAR(MAX) NOT NULL,
            PrecioEnDolares NVARCHAR(MAX) NOT NULL
        );

        -- Insertar datos desde el archivo Excel
        DECLARE @sql NVARCHAR(MAX) = '
            INSERT INTO #temporal
            SELECT *
            FROM OPENROWSET(
                ''Microsoft.ACE.OLEDB.12.0'', 
                ''Excel 12.0 Xml;HDR=YES;Database=' + @rutaArchivo + ''', 
                ''SELECT * FROM [Sheet1$]''
            ) AS ExcelData;
        ';

        EXEC sp_executesql @sql;

        -- Insertar productos en la tabla Supermercado.Producto
        INSERT INTO Supermercado.Producto (CategoriaID, NombreProducto, PrecioUnitario, PrecioUnitarioUsd, Fecha)
        SELECT 
            @CategoriaID AS CategoriaID,
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

        -- Eliminar la tabla temporal
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


CREATE OR ALTER PROCEDURE Supermercado.InsertarProductosImportados
    @rutaArchivo NVARCHAR(MAX)
AS
BEGIN
    BEGIN TRY
        CREATE TABLE #temporal (
			IdProducto NVARCHAR(MAX) NOT NULL,
            NombreProducto NVARCHAR(MAX) NOT NULL,
            Proveedor NVARCHAR(MAX) NOT NULL,
			Categoria NVARCHAR(MAX) NOT NULL,
			CantidadPorUnidad NVARCHAR(MAX) NOT NULL,
			PrecioUnidad NVARCHAR(MAX) NOT NULL
        );

		DECLARE @sql NVARCHAR(MAX) = '
			INSERT INTO #temporal
			SELECT *
			FROM OPENROWSET(
				''Microsoft.ACE.OLEDB.12.0'', 
				''Excel 12.0 Xml;HDR=YES;Database=' + @rutaArchivo + ''', 
				''SELECT * FROM [Listado de Productos$]''
			) AS ExcelData;
		';

        EXEC sp_executesql @sql;

        INSERT INTO Supermercado.Categoria (Descripcion)
        SELECT DISTINCT Categoria
        FROM #temporal
        WHERE NOT EXISTS (
            SELECT 1
            FROM Supermercado.Categoria c
            WHERE c.Descripcion = Categoria
        );


        INSERT INTO Supermercado.Producto (NombreProducto,UnidadReferencia,CategoriaID,Proveedor,PrecioUnitario, Fecha)
        SELECT  
			NombreProducto,
			CantidadPorUnidad AS UnidadReferencia,
			CategoriaID,
			Proveedor,
            TRY_CAST(PrecioUnidad AS DECIMAL(10, 2)) AS PrecioUnitario,
            GETDATE() AS Fecha
        FROM (
            SELECT 
                NombreProducto,
                PrecioUnidad,
				Proveedor,
				(SELECT ID FROM Supermercado.Categoria WHERE Descripcion = Categoria) AS CategoriaID,
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

