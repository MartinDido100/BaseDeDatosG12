-- Script que crea los procedures para importar los archivos con productos
-- Ejecutar en el orden que se desarrollan

USE Com5600G12;
GO

CREATE OR ALTER PROCEDURE Supermercado.InsertarProductosCatalogo
    @rutaArchivo NVARCHAR(MAX)
AS
BEGIN
    BEGIN TRY
        CREATE TABLE #temporal (
            id NVARCHAR(MAX),              
            category NVARCHAR(MAX) NOT NULL, 
            name NVARCHAR(MAX) NOT NULL,    
            price NVARCHAR(MAX) NOT NULL,   
            reference_price NVARCHAR(MAX) NOT NULL, 
            reference_unit NVARCHAR(100) NOT NULL, 
            date NVARCHAR(MAX) NOT NULL    
        );

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

		--Reemplazamo caracteres 
		UPDATE #temporal
		set name = REPLACE(name,'Ãº','�')
		where name like '%Ãº%'

		UPDATE #temporal
		set name = REPLACE(name,'ó','�')
		where name like '%ó%'

		UPDATE #temporal
		SET name = REPLACE(name, 'ú', '�')
		WHERE name LIKE '%ú%';

		UPDATE #temporal
		SET name = REPLACE(name, 'é', '�')
		WHERE name LIKE '%é%';

		UPDATE #temporal
		SET name = REPLACE(name, 'ñ', '�')
		WHERE name LIKE '%ñ%';

		UPDATE #temporal
		SET name = REPLACE(name, 'á', '�')
		WHERE name LIKE '%á%';

		--modifica la � pero deja un espacio por ejemplo el 16 T�nica zero calor�-as Schweppes
		UPDATE #temporal
		SET name = REPLACE(name, '�', '�')
		WHERE name LIKE '%�%';

		UPDATE #temporal
		SET name = REPLACE(name, 'º', '�')
		WHERE name LIKE '%º%';

        INSERT INTO Supermercado.Producto (Categoria, NombreProducto, PrecioUnitario, PrecioReferencia, UnidadReferencia, Fecha)
        SELECT 
            category AS Categoria,
            REPLACE(name, N'?', N'�') AS NombreProducto,
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
		DECLARE @tipoCambio DECIMAL(10, 4);

		EXEC Services.ObtenerTipoCambioUsdToArs @tipoCambio OUTPUT;

        CREATE TABLE #temporal (
            Product NVARCHAR(MAX) NOT NULL,       
            PrecioEnDolares NVARCHAR(MAX) NOT NULL
        );

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

