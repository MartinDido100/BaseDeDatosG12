USE Com5600G12
GO

sp_configure 'show advanced options', 1;
GO

RECONFIGURE;
GO

sp_configure 'Ole Automation Procedures', 1;
GO

RECONFIGURE;
GO

CREATE OR ALTER PROCEDURE Services.ObtenerTipoCambioUsdToArs
    @tipoCambio DECIMAL(10, 4) OUTPUT
AS
BEGIN
    Declare @jsonResponse as Varchar(8000);
    DECLARE @obj INT;
    DECLARE @status INT;

    -- Crear el objeto HTTP
    EXEC sp_OACreate 'MSXML2.XMLHTTP', @obj OUT;
    
    IF @obj IS NULL
    BEGIN
        PRINT 'Error al crear el objeto HTTP';
        RETURN;
    END

    EXEC sp_OAMethod @obj, 'setRequestHeader', NULL, 'Content-Type', 'application/json';

    EXEC sp_OAMethod @obj, 'open', NULL, 'GET', 'https://api.exchangerate-api.com/v4/latest/USD', 'false'; 
    
    EXEC sp_OAMethod @obj, 'send';

    EXEC sp_OAMethod @obj, 'status', @status OUT;

    EXEC sp_OAMethod @obj, 'responseText', @jsonResponse OUT;

    EXEC sp_OADestroy @obj;

	WITH JSONData AS (
        SELECT JSON_VALUE(@jsonResponse, '$.rates.ARS') AS TipoCambioUsdToArs
    )
    SELECT @tipoCambio = TipoCambioUsdToArs FROM JSONData;

    SELECT @tipoCambio AS TipoCambio;
	
END;
GO
