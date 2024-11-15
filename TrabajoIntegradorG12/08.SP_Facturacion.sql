-- Script que genera el procedure para generar notas de credito a una factura

CREATE OR ALTER PROCEDURE Supervisor.GenerarNotaDeCredito
    @FacturaID INT
AS
BEGIN
    BEGIN TRY
		BEGIN TRANSACTION;
        IF NOT EXISTS (
            SELECT 1 
            FROM Ventas.Factura 
            WHERE IDFactura = @FacturaID
            AND IdentificadorPago NOT LIKE '%--%'
        )
        BEGIN
            THROW 50000, 'La factura aun no esta pagada', 1;
        END

        INSERT INTO Ventas.Factura (nroFactura, TipoFactura, Fecha, Hora, MedioPago, Empleado, Cliente, sucursalID, IdentificadorPago, FacturaNC)
        SELECT 
            nroFactura + '-NC', 
            'NC-' + TipoFactura,
            GETDATE(), 
            SYSDATETIME(), 
            MedioPago, 
            Empleado, 
            Cliente,
            sucursalID, 
            IdentificadorPago,
            IDFactura as FacturaNC
        FROM Ventas.Factura 
        WHERE IDFactura = @FacturaID

		COMMIT;

        PRINT 'Nota de Crédito generada correctamente.';
        
    END TRY
    BEGIN CATCH
		ROLLBACK;
        PRINT 'Error al generar la Nota de Crédito.';
        PRINT ERROR_MESSAGE();
    END CATCH;
END;
GO