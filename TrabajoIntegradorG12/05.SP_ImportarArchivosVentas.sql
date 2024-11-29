-- Script que declara los procedures para importar el archivo maestro de ventas

USE Com5600G12;
GO

CREATE OR ALTER PROCEDURE Ventas.InsertarEnTablaFacturas
    @rutaArchivo NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
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

        DECLARE @sql NVARCHAR(MAX) = N'
            BULK INSERT #temp
            FROM ''' + @rutaArchivo + '''
            WITH (
                FORMAT = ''CSV'',
                CODEPAGE = ''65001'', 
                FIRSTROW = 2,
                FIELDTERMINATOR = '';'',
                ROWTERMINATOR = ''0x0A'',
                FIELDQUOTE = ''"'' 
            );
        ';

        EXEC sp_executesql @sql;

        -- Reemplazar caracteres en los productos
        UPDATE #temp
        SET Producto = REPLACE(Producto, 'ÃƒÂº', 'ú') WHERE Producto LIKE '%ÃƒÂº%';
        UPDATE #temp
        SET Producto = REPLACE(Producto, 'Ã³', 'ó') WHERE Producto LIKE '%Ã³%';
        UPDATE #temp
        SET Producto = REPLACE(Producto, 'Ãº', 'ú') WHERE Producto LIKE '%Ãº%';
        UPDATE #temp
        SET Producto = REPLACE(Producto, 'Ã©', 'é') WHERE Producto LIKE '%Ã©%';
        UPDATE #temp
        SET Producto = REPLACE(Producto, 'Ã±', 'ñ') WHERE Producto LIKE '%Ã±%';
        UPDATE #temp
        SET Producto = REPLACE(Producto, 'Ã¡', 'á') WHERE Producto LIKE '%Ã¡%';
        UPDATE #temp
        SET Producto = REPLACE(Producto, 'Ã', 'í') WHERE Producto LIKE '%Ã%';
        UPDATE #temp
        SET Producto = REPLACE(Producto, 'Âº', 'º') WHERE Producto LIKE '%Âº%';

        DECLARE @FacturaID INT;
        DECLARE @ClienteID INT;
	
		DECLARE cursor_facturas CURSOR FOR
		SELECT 
			nroFactura, TipoFactura, Ciudad, TipoCliente, Genero, Producto, 
			PrecioUnitario, Cantidad, Fecha, Hora, MedioPago, Empleado, IdentificadorPago
		FROM #temp;

		OPEN cursor_facturas;

        DECLARE @nroFactura VARCHAR(50),
                @TipoFactura VARCHAR(20),
                @Ciudad VARCHAR(50),
                @TipoCliente VARCHAR(50),
                @Genero VARCHAR(50),
                @Producto VARCHAR(200),
                @PrecioUnitario DECIMAL(10, 2),
                @Cantidad INT,
                @Fecha DATE,
                @Hora TIME,
                @MedioPago VARCHAR(50),
                @Empleado INT,
                @IdentificadorPago VARCHAR(50);

        FETCH NEXT FROM cursor_facturas INTO @nroFactura, @TipoFactura, @Ciudad, @TipoCliente, @Genero, @Producto, @PrecioUnitario, @Cantidad, @Fecha, @Hora, @MedioPago, @Empleado, @IdentificadorPago;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SELECT @ClienteID = ClienteID
            FROM Supermercado.Cliente
            WHERE TipoCliente = @TipoCliente AND Genero = @Genero;

            IF @ClienteID IS NULL
            BEGIN
                INSERT INTO Supermercado.Cliente (TipoCliente, Genero)
                VALUES (@TipoCliente, @Genero);

                -- Obtener el ClienteID recién insertado
                SET @ClienteID = SCOPE_IDENTITY();
            END

            IF EXISTS (SELECT 1 FROM Supermercado.EmpleadoEncriptado WHERE Legajo = @Empleado)
               AND EXISTS (SELECT 1 FROM Supermercado.Producto WHERE NombreProducto = @Producto AND deleted_at IS NULL)
            BEGIN
                -- Insertar la factura si no existe
                IF NOT EXISTS (SELECT 1 FROM Ventas.Factura WHERE nroFactura = @nroFactura)
                BEGIN
                    INSERT INTO Ventas.Factura (nroFactura, TipoFactura, sucursalID, Fecha, Hora, MedioPago, Empleado, IdentificadorPago, ClienteID)
                    VALUES (
                        @nroFactura, 
                        @TipoFactura, 
                        (SELECT TOP 1 SucursalID FROM Supermercado.Sucursal WHERE CiudadFake = @Ciudad), 
                        @Fecha, 
                        @Hora, 
                        (SELECT TOP 1 IdMedioPago FROM Ventas.MediosPago WHERE Descripcion = @MedioPago), 
                        (SELECT TOP 1 EmpleadoID FROM Supermercado.EmpleadoEncriptado WHERE Legajo = @Empleado), 
                        @IdentificadorPago,
                        @ClienteID
                    );

                    SET @FacturaID = SCOPE_IDENTITY(); -- Captura el ID de la factura insertada
                END
                ELSE
                BEGIN
                    SELECT @FacturaID = IDFactura FROM Ventas.Factura WHERE nroFactura = @nroFactura;
                END

                -- Insertar en la línea de factura
                INSERT INTO Ventas.LineaFactura (Cantidad, ProductoID, FacturaID, PrecioU)
                SELECT 
                    @Cantidad, 
                    (SELECT TOP 1 ProductoID FROM Supermercado.Producto WHERE NombreProducto = @Producto), 
                    @FacturaID, 
                    @PrecioUnitario 
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM Ventas.LineaFactura
                    WHERE FacturaID = @FacturaID
                    AND ProductoID = (SELECT TOP 1 ProductoID FROM Supermercado.Producto WHERE NombreProducto = @Producto)
                );
            END

            FETCH NEXT FROM cursor_facturas INTO @nroFactura, @TipoFactura, @Ciudad, @TipoCliente, @Genero, @Producto, @PrecioUnitario, @Cantidad, @Fecha, @Hora, @MedioPago, @Empleado, @IdentificadorPago;
        END

        CLOSE cursor_facturas;
        DEALLOCATE cursor_facturas;

        DROP TABLE #temp;

    END TRY
    BEGIN CATCH
        PRINT 'Error al insertar los datos en la tabla Ventas.Factura.';
        PRINT ERROR_MESSAGE();
    END CATCH;
END;
GO