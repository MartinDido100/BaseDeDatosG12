-- Script que crea procedures con consultas comunes, como agregar datos a tablas, actualizar y eliminar
-- El orden de ejecucion es tal cual estan desarrollados

USE Com5600G12;
GO

-- INSERTAR EN TABLA PRODUCTO
CREATE OR ALTER PROCEDURE Supermercado.InsertarNuevoProducto
    @Categoria VARCHAR(200),
    @NombreProducto VARCHAR(200),
    @PrecioUnitario DECIMAL(10, 2),
    @PrecioUnitarioUsd DECIMAL(10, 2),
    @PrecioReferencia DECIMAL(10, 2),
    @UnidadReferencia VARCHAR(100)
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Supermercado.Producto WHERE NombreProducto = @NombreProducto AND deleted_at IS NULL)
    BEGIN
        DECLARE @FechaActual DATETIME;
        SET @FechaActual = GETDATE();
        INSERT INTO Supermercado.Producto (Categoria, NombreProducto, PrecioUnitario, PrecioReferencia, UnidadReferencia, Fecha)
        VALUES (@Categoria, @NombreProducto, @PrecioUnitario, @PrecioReferencia, @UnidadReferencia, @FechaActual);
    END
    ELSE
    BEGIN
        PRINT 'El producto ya existe o fue borrado';
    END
END;
GO

-- INSERTAR UNA NUEVA FACTURA
CREATE OR ALTER PROCEDURE Ventas.CrearFactura
    @nroFactura VARCHAR(50),
    @TipoFactura VARCHAR(10),
    @Sucursal INT,
    @Cliente INT,
    @Hora TIME,
    @MedioPago INT,
    @Empleado INT
AS
BEGIN
    DECLARE @Fecha DATETIME;
    SET @Fecha = GETDATE();
    
    IF NOT EXISTS (SELECT 1 FROM Ventas.Factura WHERE nroFactura = @nroFactura)
    BEGIN
        INSERT INTO Ventas.Factura (
            nroFactura, TipoFactura, sucursalID, 
            Fecha, Hora, MedioPago, Empleado)
        VALUES (
            @nroFactura, @TipoFactura, @Sucursal, @Fecha, @Hora, @MedioPago, @Empleado);
    END
    ELSE
    BEGIN
        PRINT 'La factura con este número ya existe y no se ha insertado.';
    END
END;
GO

-- INSERTAR NUEVA SUCURSAL
CREATE OR ALTER PROCEDURE Supermercado.InsertarNuevaSucursal
    @CiudadSucursal VARCHAR(50),
    @DireccionSucursal VARCHAR(200),
    @Telefono VARCHAR(30),
	@Horario VARCHAR(100)
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Supermercado.Sucursal WHERE Ciudad = @CiudadSucursal AND Direccion = @DireccionSucursal)
    BEGIN
        INSERT INTO Supermercado.Sucursal (Ciudad, Direccion, Telefono,Horario)
        VALUES (@CiudadSucursal, @DireccionSucursal, @Telefono,@Horario);
    END
    ELSE
    BEGIN
        PRINT 'La sucursal en esta ciudad y dirección ya existe y no se ha insertado.';
    END
END;
GO

-- INSERTAR NUEVO CLIENTE
CREATE OR ALTER PROCEDURE Supermercado.InsertarNuevoCliente
    @NombreCliente VARCHAR(100),
    @CiudadCliente VARCHAR(100),
    @TipoCliente VARCHAR(30),
    @Genero CHAR(1)
AS
BEGIN
    INSERT INTO Supermercado.Cliente (Nombre, Ciudad, TipoCliente, Genero)
    VALUES (@NombreCliente, @CiudadCliente, @TipoCliente, @Genero);
END;
GO

-- INSERTAR NUEVO EMPLEADO
CREATE OR ALTER PROCEDURE Supermercado.InsertarNuevoEmpleado
    @Legajo INT,
    @NombreEmpleado VARCHAR(100),
    @Apellido VARCHAR(100),
    @Dni INT,
    @Direccion VARCHAR(100),
    @Email VARCHAR(100),
    @EmailEmpresa VARCHAR(100),
    @Cargo VARCHAR(50),
    @SucursalID INT,
    @Turno VARCHAR(30)
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Supermercado.Empleado WHERE Legajo = @Legajo OR Dni = @Dni)
    BEGIN
        INSERT INTO Supermercado.Empleado (Legajo, Nombre, Apellido, Dni, Direccion, Email, EmailEmpresa, Cargo, SucursalID, Turno)
        VALUES (@Legajo, @NombreEmpleado, @Apellido, @Dni, @Direccion, @Email, @EmailEmpresa, @Cargo, @SucursalID, @Turno);
    END
    ELSE
    BEGIN
        PRINT 'El empleado con este Legajo o DNI ya existe y no se ha insertado.';
    END
END;
GO

-- INSERTAR NUEVO MEDIO DE PAGO
CREATE OR ALTER PROCEDURE Ventas.InsertarNuevoMedioPago
    @MedioPagoName VARCHAR(50),
    @Descripcion VARCHAR(255)
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Ventas.MediosPago WHERE MedioPagoName = @MedioPagoName)
    BEGIN
        INSERT INTO Ventas.MediosPago (MedioPagoName, Descripcion)
        VALUES (@MedioPagoName, @Descripcion);
    END
    ELSE
    BEGIN
        PRINT 'El medio de pago ya existe y no se ha insertado.';
    END
END;
GO

-- BORRADO LÓGICO DE PRODUCTO
CREATE OR ALTER PROCEDURE Supermercado.EliminarProducto
    @ProductoID INT
AS
BEGIN
    BEGIN TRY
        -- Verificar existencia del producto
        IF EXISTS (SELECT 1 FROM Supermercado.Producto WHERE ProductoID = @ProductoID AND deleted_at IS NULL)
        BEGIN
            DECLARE @FechaActual DATETIME = GETDATE();
            UPDATE Supermercado.Producto SET deleted_at = @FechaActual WHERE ProductoID = @ProductoID;
            PRINT 'Producto eliminado lógicamente exitosamente.';
        END
        ELSE
        BEGIN
            PRINT 'El producto no existe o ya fue eliminado.';
        END
    END TRY
    BEGIN CATCH
        PRINT 'Error al eliminar el producto:';
        PRINT ERROR_MESSAGE();
    END CATCH
END;
GO

--INSERTAR LINEA DE FACTURA
CREATE OR ALTER PROCEDURE Ventas.CrearLineaFactura
    @FacturaID INT,
    @ProductoID INT,
    @Cantidad INT,
    @PrecioU DECIMAL(10, 2)
AS
BEGIN
    BEGIN TRY

        IF EXISTS (SELECT 1 FROM Ventas.Factura WHERE IDFactura = @FacturaID)
            AND EXISTS (SELECT 1 FROM Supermercado.Producto WHERE ProductoID = @ProductoID AND deleted_at IS NULL)
        BEGIN

            IF EXISTS (SELECT 1 FROM Ventas.LineaFactura WHERE FacturaID = @FacturaID AND ProductoID = @ProductoID)
            BEGIN
                PRINT 'El producto ya está en la factura.';
            END
            ELSE
            BEGIN

                INSERT INTO Ventas.LineaFactura (FacturaID, ProductoID, Cantidad, PrecioU)
                VALUES (@FacturaID, @ProductoID, @Cantidad, @PrecioU);
                PRINT 'Línea de producto creada exitosamente.';
            END
        END
        ELSE
        BEGIN
            PRINT 'La factura o el producto no existen o el producto ha sido eliminado.';
        END
    END TRY
    BEGIN CATCH
        PRINT 'Error al crear la línea de producto:';
        PRINT ERROR_MESSAGE();
    END CATCH
END;
GO


--EMITIR FACTURA
CREATE OR ALTER PROCEDURE Ventas.PagarFactura
    @IDFactura INT,
    @IdentificadorPago VARCHAR(100)
AS
BEGIN
    BEGIN TRY
        IF EXISTS (SELECT 1 FROM Ventas.Factura WHERE IDFactura = @IDFactura AND IdentificadorPago IS NULL)
        BEGIN
            UPDATE Ventas.Factura
            SET IdentificadorPago = @IdentificadorPago
            WHERE IDFactura = @IDFactura;
            PRINT 'Factura pagada exitosamente.';
        END
        ELSE
        BEGIN
            PRINT 'La factura no existe o ya fue pagada.';
        END
    END TRY
    BEGIN CATCH
        PRINT 'Error al pagar la factura:';
        PRINT ERROR_MESSAGE();
    END CATCH
END;
GO