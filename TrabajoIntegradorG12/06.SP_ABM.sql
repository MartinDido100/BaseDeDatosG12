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
        PRINT 'La factura con este n�mero ya existe y no se ha insertado.';
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
        PRINT 'La sucursal en esta ciudad y direcci�n ya existe y no se ha insertado.';
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

--INSERTAR EMPLEADO ENCRIPTADO
CREATE OR ALTER PROCEDURE Supervisor.InsertarNuevoEmpleadoEncriptado --SOLO PARA Supervisores
    @Legajo INT,
    @NombreEmpleado NVARCHAR(100),
    @Apellido NVARCHAR(100),
    @Dni INT,
    @Direccion NVARCHAR(100),
    @Email NVARCHAR(100),
    @EmailEmpresa NVARCHAR(100),
    @Cargo NVARCHAR(50),
    @SucursalID INT,
    @Turno NVARCHAR(30),
    @FraseClave NVARCHAR(128)
AS
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM Supermercado.EmpleadoEncriptado 
        WHERE Legajo = @Legajo 
        OR Dni = EncryptByPassPhrase(@FraseClave, CONVERT(NVARCHAR(100), @Dni))
    )
    BEGIN
        INSERT INTO Supermercado.EmpleadoEncriptado (Legajo, Nombre, Apellido, Dni, Direccion, Email, EmailEmpresa, Cargo, SucursalID, Turno)
        VALUES (
            @Legajo,
            EncryptByPassPhrase(@FraseClave, @NombreEmpleado),
            EncryptByPassPhrase(@FraseClave, @Apellido),
            EncryptByPassPhrase(@FraseClave, CONVERT(NVARCHAR(100), @Dni)),
            EncryptByPassPhrase(@FraseClave, @Direccion),
            EncryptByPassPhrase(@FraseClave, @Email),
            @EmailEmpresa,  
            @Cargo,        
            @SucursalID,
            @Turno
        );
        PRINT 'Empleado insertado exitosamente con datos encriptados.';
    END
    ELSE
    BEGIN
        PRINT 'El empleado con este Legajo o DNI ya existe y no se ha insertado.';
    END
END;
GO

CREATE OR ALTER PROCEDURE Supervisor.mostrarTablaEmpleadoEncriptada --SOLO PARA ADMINS
    @FraseClave NVARCHAR(128)
AS
BEGIN
    BEGIN TRY
        SELECT 
            Legajo,
            CONVERT(NVARCHAR(100), DecryptByPassPhrase(@FraseClave, Nombre)) AS Nombre,
            CONVERT(NVARCHAR(100), DecryptByPassPhrase(@FraseClave, Apellido)) AS Apellido,
            CONVERT(INT, DecryptByPassPhrase(@FraseClave, CONVERT(VARBINARY(256), Dni))) AS DNI, 
            CONVERT(NVARCHAR(100), DecryptByPassPhrase(@FraseClave, Direccion)) AS Direccion,
            CONVERT(NVARCHAR(100), DecryptByPassPhrase(@FraseClave, Email)) AS Email,
            EmailEmpresa,
            Cargo,
            SucursalID,
            Turno
        FROM 
            Supermercado.EmpleadoEncriptado;
    END TRY
    BEGIN CATCH
        PRINT 'Error al desencriptar los datos de la tabla Supermercado.EmpleadoEncriptado:';
        PRINT ERROR_MESSAGE();
    END CATCH;
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

-- BORRADO L�GICO DE PRODUCTO
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
            PRINT 'Producto eliminado l�gicamente exitosamente.';
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
                PRINT 'El producto ya est� en la factura.';
            END
            ELSE
            BEGIN

                INSERT INTO Ventas.LineaFactura (FacturaID, ProductoID, Cantidad, PrecioU)
                VALUES (@FacturaID, @ProductoID, @Cantidad, @PrecioU);
                PRINT 'L�nea de producto creada exitosamente.';
            END
        END
        ELSE
        BEGIN
            PRINT 'La factura o el producto no existen o el producto ha sido eliminado.';
        END
    END TRY
    BEGIN CATCH
        PRINT 'Error al crear la l�nea de producto:';
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

CREATE OR ALTER PROCEDURE Ventas.MostrarReporteVentas
AS
BEGIN
    SELECT
        f.IDFactura AS [ID FACTURA],
        f.TipoFactura AS [TIPO DE FACTURA],
        s.Ciudad AS [CIUDAD],
        c.TipoCliente AS [TIPO DE CLIENTE],
        c.Genero AS [GENERO],
        p.NombreProducto AS [PRODUCTO],
        p.PrecioUnitario AS [PRECIO UNITARIO],
        f.Cantidad AS [CANTIDAD],
        f.Fecha AS [FECHA],
        mp.Descripcion AS [MEDIO DE PAGO],
        e.Legajo AS [EMPLEADO],
        s.Ciudad AS [SUCURSAL]
    FROM 
        Ventas.Factura f
    JOIN 
        Supermercado.Cliente c ON f.Cliente = c.ClienteID
    JOIN 
        Supermercado.Producto p ON f.Producto = p.ProductoID
    JOIN 
        Ventas.MediosPago mp ON f.MedioPago = mp.MedioPagoName
    JOIN 
        Supermercado.Empleado e ON f.Empleado = e.Legajo
    JOIN 
        Supermercado.Sucursal s ON f.Sucursal = s.SucursalID;
END;
GO