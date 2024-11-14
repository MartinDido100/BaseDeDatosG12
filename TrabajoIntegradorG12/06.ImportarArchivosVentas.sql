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
                FORMAT = ''CSV'',
                CODEPAGE = ''1200'', -- UTF-16 LE
                FIRSTROW = 2,
                FIELDTERMINATOR = '';'',
                ROWTERMINATOR = ''0x0A'',
                FIELDQUOTE = ''"'' 
            );
        ';

        -- Ejecutar el BULK INSERT de manera dinámica
        EXEC sp_executesql @sql;

        DECLARE @FacturaID INT;

        -- Cursor para recorrer los registros de la tabla temporal
        DECLARE cursor_facturas CURSOR FOR 
        SELECT * FROM #temp;

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
            IF EXISTS (SELECT 1 FROM Supermercado.Empleado WHERE Legajo = @Empleado)
            BEGIN

                IF NOT EXISTS (SELECT 1 FROM Ventas.Factura WHERE nroFactura = @nroFactura)
                BEGIN
                    -- Crear la factura si no existe
                    INSERT INTO Ventas.Factura (nroFactura, TipoFactura, sucursalID, Fecha, Hora, MedioPago, Empleado, Cliente, IdentificadorPago)
                    VALUES (
                        @nroFactura, 
                        @TipoFactura, 
                        (SELECT SucursalID FROM Supermercado.Sucursal WHERE CiudadFake = @Ciudad), -- Asigna sucursalID desde el Empleado
                        @Fecha, 
                        @Hora, 
                        (SELECT IdMedioPago FROM Ventas.MediosPago WHERE Descripcion = @MedioPago), 
                        (SELECT EmpleadoID FROM Supermercado.Empleado WHERE Legajo = @Empleado), -- Asigna EmpleadoID, no Legajo
                        2, -- Asigna aquí ClienteID según la lógica deseada
                        @IdentificadorPago
                    );

                    SET @FacturaID = SCOPE_IDENTITY(); -- Captura el ID de la factura insertada
				END
                ELSE
				BEGIN
					 SELECT @FacturaID = IDFactura FROM Ventas.Factura WHERE nroFactura = @nroFactura;
				END

                -- Insertar la Línea de Factura
				INSERT INTO Ventas.LineaFactura (Cantidad, ProductoID, FacturaID, Subtotal)
				SELECT 
					@Cantidad, 
					(SELECT ProductoID FROM Supermercado.Producto WHERE NombreProducto = @Producto), 
					@FacturaID, 
					@PrecioUnitario * @Cantidad
					WHERE NOT EXISTS (
						SELECT 1
						FROM Ventas.LineaFactura
						WHERE FacturaID = @FacturaID
						AND ProductoID = (SELECT ProductoID FROM Supermercado.Producto WHERE NombreProducto = @Producto)
					);
            END

            FETCH NEXT FROM cursor_facturas INTO @nroFactura, @TipoFactura, @Ciudad, @TipoCliente, @Genero, @Producto, @PrecioUnitario, @Cantidad, @Fecha, @Hora, @MedioPago, @Empleado, @IdentificadorPago;
        END

        CLOSE cursor_facturas;
        DEALLOCATE cursor_facturas;

        -- Limpiar la tabla temporal después de usarla
        DROP TABLE #temp;

    END TRY
    BEGIN CATCH
        -- Si ocurre un error, muestra el mensaje de error
        PRINT 'Error al insertar los datos en la tabla Ventas.Factura.';
        PRINT ERROR_MESSAGE();
    END CATCH;
END;
GO

EXEC Ventas.InsertarEnTablaFacturas 'C:\Users\marti\Desktop\BBDD Ap\TrabajoIntegradorG12\Ventas_registradas.csv'
GO