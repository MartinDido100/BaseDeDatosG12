USE Com5600G12;
GO

CREATE OR ALTER PROCEDURE Supervisor.Backup_Completo
    @RutaBackup NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NombreArchivo NVARCHAR(256);
    DECLARE @BaseDeDatos NVARCHAR(128) = 'Com5600G12'; 
    

    SET @NombreArchivo = @RutaBackup + '\' + @BaseDeDatos + '_Full.bak';

    BACKUP DATABASE @BaseDeDatos
    TO DISK = @NombreArchivo
    WITH INIT, FORMAT;

    PRINT 'Respaldo completo realizado con Exito: ' + @NombreArchivo;
END;
GO



CREATE OR ALTER PROCEDURE Supervisor.Backup_Diferencial
    @RutaBackup NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NombreArchivo NVARCHAR(256);
    DECLARE @BaseDeDatos NVARCHAR(128) = 'Com5600G12';  
    

    SET @NombreArchivo = @RutaBackup + '\' + @BaseDeDatos + '_Differential.bak';

    -- Realizar el respaldo diferencial
    BACKUP DATABASE @BaseDeDatos
    TO DISK = @NombreArchivo
    WITH DIFFERENTIAL, INIT, FORMAT;

    PRINT 'Respaldo diferencial realizado con �xito: ' + @NombreArchivo;
END;
GO


CREATE OR ALTER PROCEDURE Supervisor.Backup_Log
    @RutaBackup NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NombreArchivo NVARCHAR(256);
    DECLARE @BaseDeDatos NVARCHAR(128) = 'Com5600G12';  -- Nombre de la base de datos fija
    
    SET @NombreArchivo = @RutaBackup + '\' + @BaseDeDatos + '_Log.trn';

    -- Realizar el respaldo del log de transacciones
    BACKUP LOG @BaseDeDatos
    TO DISK = @NombreArchivo
    WITH INIT, FORMAT;

    PRINT 'Respaldo del log realizado con �xito: ' + @NombreArchivo;
END;
GO



--RESTAURACION COMPLETA CONCATENANDO LOS 3 TIPOS DE RESPALDO PARA ASEGURARME DE NO PERDER INFORMACION
--REQUISITO PARA EJECUTAR ESE PROCEDURE: NO ESTAR USANDO LA BD QUE SE VA A RESTAURAR
use master
GO
CREATE OR ALTER PROCEDURE RestaurarBaseDeDatos
    @Ruta NVARCHAR(255)
AS
BEGIN
    DECLARE @BaseDeDatos NVARCHAR(128) = 'Com5600G12'

    --Armo las rutas de backup
    DECLARE @ArchivoCompleto NVARCHAR(512)
    SET @ArchivoCompleto = @Ruta + '\' + @BaseDeDatos + '_Full.bak'


    PRINT 'Restaurando respaldo completo...'
    RESTORE DATABASE @BaseDeDatos
    FROM DISK = @ArchivoCompleto
    WITH REPLACE, NORECOVERY, FILE = 1; -- No recovery para aplicar los respaldos posteriores

    DECLARE @ArchivoDiferencial NVARCHAR(512)
    SET @ArchivoDiferencial = @Ruta + '\' + @BaseDeDatos + '_Differential.bak'

    PRINT 'Restaurando respaldo diferencial...'
    RESTORE DATABASE @BaseDeDatos
    FROM DISK = @ArchivoDiferencial
    WITH NORECOVERY, FILE = 1;

    DECLARE @ArchivoLog NVARCHAR(512)
    SET @ArchivoLog = @Ruta + '\' + @BaseDeDatos + '_Log.trn'

    PRINT 'Restaurando respaldo de log...'
    RESTORE LOG @BaseDeDatos
    FROM DISK = @ArchivoLog
    WITH RECOVERY, FILE = 1; -- Con recovery para finalizar la restauraci�n

    PRINT 'Base de datos restaurada con �xito.'
END
GO


--TEST BACKUPS
USE Com5600G12;
GO
--REALIZO LOS 3 TIPOS DE BACKUPS
EXEC Supervisor.Backup_Completo 'C:\Users\Usuario\Desktop\Backups'
EXEC Supervisor.Backup_Diferencial 'C:\Users\Usuario\Desktop\Backups'
EXEC Supervisor.Backup_Log 'C:\Users\Usuario\Desktop\Backups'

--RESTAURACION COMPLETA DE LA BASE DE DATOS, REQUIERE USAR OTRA BASE DE DATO
use master
EXEC RestaurarBaseDeDatos 'C:\Users\Usuario\Desktop\Backups'

