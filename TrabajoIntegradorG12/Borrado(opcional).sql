USE Com5600G12
GO

--OBJECT_ID ( 'nombre_del_objeto' , 'tipo_objeto' )
--borro la tabla si es existe, nose si es necesario y es peligroso, es solo para hacer las pruebas en limpio, no deberia ir en el
--projecto final, ya que es peligroso

CREATE OR ALTER PROCEDURE Supermercado.borrarTablas
AS
BEGIN

    -- Eliminar las tablas en el orden adecuado, asegurando que no haya conflictos de FK
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

END;
GO

EXEC Supermercado.borrarTablas;