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
                CODEPAGE = ''1200'', -- UTF-16 LE
                FIRSTROW = 2,
                FIELDTERMINATOR = '';'',
                ROWTERMINATOR = ''0x0A'',
                FIELDQUOTE = ''"'' 
            );
        ';

        EXEC sp_executesql @sql;

        DECLARE @FacturaID INT;

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
                    INSERT INTO Ventas.Factura (nroFactura, TipoFactura, sucursalID, Fecha, Hora, MedioPago, Empleado, Cliente, IdentificadorPago)
                    VALUES (
                        @nroFactura, 
                        @TipoFactura, 
                        (SELECT SucursalID FROM Supermercado.Sucursal WHERE CiudadFake = @Ciudad), -- Asigna sucursalID desde el Empleado
                        @Fecha, 
                        @Hora, 
                        (SELECT IdMedioPago FROM Ventas.MediosPago WHERE Descripcion = @MedioPago), 
                        (SELECT EmpleadoID FROM Supermercado.Empleado WHERE Legajo = @Empleado), -- Asigna EmpleadoID, no Legajo
                        2, -- Asigna aqu� ClienteID seg�n la l�gica deseada
                        @IdentificadorPago
                    );

                    SET @FacturaID = SCOPE_IDENTITY(); -- Captura el ID de la factura insertada
				END
                ELSE
				BEGIN
					 SELECT @FacturaID = IDFactura FROM Ventas.Factura WHERE nroFactura = @nroFactura;
				END

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

        DROP TABLE #temp;

    END TRY
    BEGIN CATCH
        PRINT 'Error al insertar los datos en la tabla Ventas.Factura.';
        PRINT ERROR_MESSAGE();
    END CATCH;
END;
GO