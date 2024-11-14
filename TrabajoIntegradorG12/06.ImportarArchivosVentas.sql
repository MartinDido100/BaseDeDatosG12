USE Com5600G12;
GO

CREATE OR ALTER PROCEDURE Ventas.InsertarEnTablaFacturas
    @rutaArchivo NVARCHAR(MAX)
AS
BEGIN
    -- Manejo de errores
    BEGIN TRY
        -- Crear una tabla TEMPORAL para almacenar los datos del archivo CSV
    
        CREATE TABLE #temp (
            nroFactura VARCHAR(50),
            TipoFactura VARCHAR(20),
            Ciudad VARCHAR(50),
            TipoCliente VARCHAR(50),
            Genero VARCHAR(50),
            Producto VARCHAR(200),
            PrecioUnitario DECIMAL(10, 2),
            Cantidad INT,
            Fecha DATE,
            Hora TIME,
            MedioPago VARCHAR(50),
            Empleado INT,
            IdentificadorPago VARCHAR(50)
        );

        -- Construir el comando BULK INSERT de forma dinámica
        DECLARE @sql NVARCHAR(MAX) = N'
            BULK INSERT #temp
            FROM ''' + @rutaArchivo + '''
            WITH (
                format =''CSV'',
				CODEPAGE = ''1200'',-- UTF-16 LE
				FIRSTROW = 2,
				FIELDTERMINATOR = '';'',
				ROWTERMINATOR = ''0x0A'',
				FIELDQUOTE =''"''
            );
        ';

        -- Ejecutar el BULK INSERT de manera dinámica
        EXEC sp_executesql @sql;

        -- Insertar los datos en la tabla definitiva Supermercado.Ventas con conversión de tipos
        INSERT INTO Ventas.Factura ( nroFactura,TipoFactura,Ciudad, TipoCliente, Genero, Producto,
										PrecioUnitario, Cantidad, Fecha, Hora, MedioPago, Empleado, IdentificadorPago)
		SELECT
			t.nroFactura,
			t.TipoFactura, 
			t.Ciudad, 
			t.TipoCliente, 
			t.Genero,
			p.ProductoID,
			TRY_CAST(t.PrecioUnitario AS DECIMAL(10, 2)),
			TRY_CAST(t.Cantidad AS INT),
			TRY_CAST(t.Fecha AS DATE),
			TRY_CAST(t.Hora AS TIME),
			t.MedioPago,
			TRY_CAST(t.Empleado AS INT),
			NULLIF(t.IdentificadorPago, '--') AS IdentificadorPago
		FROM #temp t
		LEFT JOIN Supermercado.Producto p
			ON p.NombreProducto = t.Producto
        WHERE
            TRY_CAST(t.PrecioUnitario AS DECIMAL(10, 2)) IS NOT NULL AND
            TRY_CAST(t.Cantidad AS INT) IS NOT NULL AND
            TRY_CAST(t.Fecha AS DATE) IS NOT NULL AND
            TRY_CAST(t.Hora AS TIME) IS NOT NULL AND
            TRY_CAST(t.Empleado AS INT) IS NOT NULL;

    END TRY
    BEGIN CATCH
        -- Si ocurre un error, muestra el mensaje de error
        PRINT 'Error al insertar los datos en la tabla Ventas.Factura.';
        PRINT ERROR_MESSAGE();
    END CATCH;
	DROP TABLE #temp;
END;
GO

EXEC Ventas.InsertarEnTablaFacturas 'C:\Users\marti\Desktop\BBDD Ap\TrabajoIntegradorG12\Ventas_registradas.csv'
GO