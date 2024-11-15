-- Script para borras las tablas de la base de datos
-- ACLARACION: ESTE SCRIPT ES TOTALMENTE OPCIONAL Y SE USO SOLO PARA EL DESARROLLO DEL PROYECTO

USE Com5600G12
GO

--OBJECT_ID ( 'nombre_del_objeto' , 'tipo_objeto' )
--borro la tabla si es existe, nose si es necesario y es peligroso, es solo para hacer las pruebas en limpio, no deberia ir en el
--proyecto final, ya que es peligroso

CREATE OR ALTER PROCEDURE Supervisor.borrarTablas
AS
BEGIN

    IF OBJECT_ID(N'Supermercado.Venta', N'U') IS NOT NULL
        DROP TABLE Ventas.Factura;

    IF OBJECT_ID(N'Supermercado.MediosPago', N'U') IS NOT NULL
        DROP TABLE Ventas.MediosPago;

    IF OBJECT_ID(N'Supermercado.Producto', N'U') IS NOT NULL
        DROP TABLE Supermercado.Producto;

    IF OBJECT_ID(N'Supermercado.Empleado', N'U') IS NOT NULL
        DROP TABLE Supermercado.Empleado;

    IF OBJECT_ID(N'Supermercado.Cliente', N'U') IS NOT NULL
        DROP TABLE Supermercado.Cliente;

    IF OBJECT_ID(N'Supermercado.Sucursal', N'U') IS NOT NULL
        DROP TABLE Supermercado.Sucursal;

	IF OBJECT_ID(N'Supermercado.EmpleadoEncriptado', N'U') IS NOT NULL
        DROP TABLE Supermercado.EmpleadoEncriptado;

END;
GO

EXEC Supermercado.borrarTablas;