USE Com5600G12
GO

CREATE PROCEDURE CrearNotaDeCreditoPorProducto
    @FacturaOriginalID INT,
    @ProductoID INT,
    @Cantidad INT
AS
BEGIN
    BEGIN TRANSACTION;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Ventas.Factura WHERE IDFactura = @FacturaOriginalID)
        BEGIN
            THROW 50000, 'La factura a anular no existe.', 1;
        END

        DECLARE @CantidadEnFactura INT;
        SELECT @CantidadEnFactura = Cantidad
        FROM Ventas.LineaFactura
        WHERE FacturaID = @FacturaOriginalID AND ProductoID = @ProductoID;

        IF @CantidadEnFactura IS NULL
        BEGIN
            THROW 50001, 'El producto no está asociado a la factura.', 1;
        END

        -- Verificar que la cantidad a devolver sea válida
        IF @Cantidad > @CantidadEnFactura
        BEGIN
            THROW 50002, 'La cantidad solicitada excede la cantidad registrada en la factura.', 1;
        END

        -- Insertar la Nota de Crédito en la tabla Ventas.Factura
        DECLARE @NDCId INT;
        INSERT INTO Ventas.Factura (nroFactura, TipoFactura, sucursalID, clienteID, Fecha, Hora, MedioPago, Empleado, IdentificadorPago)
        SELECT
            CONCAT('NDC-', nroFactura),
            'Nota de Crédito',
            sucursalID,
            clienteID,
            GETDATE(),
            CONVERT(TIME, GETDATE()),
            MedioPago,
            Empleado,
            NULL
        FROM Ventas.Factura
        WHERE IDFactura = @FacturaOriginalID;

        SET @NDCId = SCOPE_IDENTITY();

        DECLARE @PrecioU DECIMAL(10, 2);
        SELECT @PrecioU = PrecioU
        FROM Ventas.LineaFactura
        WHERE FacturaID = @FacturaOriginalID AND ProductoID = @ProductoID;

        INSERT INTO Ventas.LineaNDC (Cantidad, ProductoID, FacturaID, LineaFacturaID, PrecioU)
        SELECT
            @Cantidad,
            ProductoID,
            @NDCId,
            IDLineaFactura,
            @PrecioU
        FROM Ventas.LineaFactura
        WHERE FacturaID = @FacturaOriginalID AND ProductoID = @ProductoID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
