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
    -- Verificar si el NombreProducto ya existe en la tabla
    IF NOT EXISTS (SELECT 1 FROM Supermercado.Producto WHERE NombreProducto = @NombreProducto)
    BEGIN
        -- Insertar solo si el producto no existe
        DECLARE @FechaActual DATETIME;
        SET @FechaActual = GETDATE();
        INSERT INTO Supermercado.Producto (Categoria, NombreProducto, PrecioUnitario, PrecioReferencia, UnidadReferencia, Fecha)
        VALUES (@Categoria, @NombreProducto, @PrecioUnitario, @PrecioReferencia, @UnidadReferencia, @FechaActual);
    END
    ELSE
    BEGIN
        PRINT 'El producto ya existe y no se ha insertado.';
    END
END;
GO



-- INSERTAR UNA NUEVA FACTURA
CREATE OR ALTER PROCEDURE Ventas.InsertarNuevaFactura
    @nroFactura VARCHAR(50),
    @TipoFactura VARCHAR(10),
    @FacturaNC INT, -- Cambiado de IDFacturaNC a FacturaNC
    @Sucursal INT,
    @Cliente INT,
    @Producto INT,
    @Cantidad INT,
    @Hora TIME,
    @MedioPago VARCHAR(50),
    @Empleado INT,
    @IdentificadorPago VARCHAR(50)
AS
BEGIN
    -- Declaración de la fecha con tipo de datos DATETIME
    DECLARE @Fecha DATETIME;
    SET @Fecha = GETDATE();
    
    IF NOT EXISTS (SELECT 1 FROM Ventas.Factura WHERE nroFactura = @nroFactura)
    BEGIN
        INSERT INTO Ventas.Factura (
            nroFactura, TipoFactura, FacturaNC, Sucursal, Cliente, Producto, 
            Cantidad, Fecha, Hora, MedioPago, Empleado, IdentificadorPago)
        VALUES (
            @nroFactura, @TipoFactura, @FacturaNC, @Sucursal, @Cliente, @Producto, 
            @Cantidad, @Fecha, @Hora, @MedioPago, @Empleado, @IdentificadorPago);
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
    @Telefono VARCHAR(30)
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Supermercado.Sucursal WHERE Ciudad = @CiudadSucursal AND Direccion = @DireccionSucursal)
    BEGIN
        INSERT INTO Supermercado.Sucursal (Ciudad, Direccion, Telefono)
        VALUES (@CiudadSucursal, @DireccionSucursal, @Telefono);
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

--INSERTAR EMPLEADO ENCRIPTADO
CREATE OR ALTER PROCEDURE Supermercado.InsertarNuevoEmpleadoEncriptado --SOLO PARA ADMINS
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
    -- Verificar si el empleado ya existe
    IF NOT EXISTS (
        SELECT 1 
        FROM Supermercado.EmpleadoEncriptado 
        WHERE Legajo = @Legajo 
        OR Dni = EncryptByPassPhrase(@FraseClave, CONVERT(NVARCHAR(100), @Dni))
    )
    BEGIN
        -- Insertar los datos en la tabla EmpleadoEncriptado con encriptación
        INSERT INTO Supermercado.EmpleadoEncriptado (Legajo, Nombre, Apellido, Dni, Direccion, Email, EmailEmpresa, Cargo, SucursalID, Turno)
        VALUES (
            @Legajo,
            EncryptByPassPhrase(@FraseClave, @NombreEmpleado),
            EncryptByPassPhrase(@FraseClave, @Apellido),
            EncryptByPassPhrase(@FraseClave, CONVERT(NVARCHAR(100), @Dni)),  -- C--NO ENTIENDO BIEN PQ TENGO QUE CONVERTIRLO CUANDO LO CREE COMO VARBINARY, PERO SI NO ME TIRA ERROR
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





CREATE OR ALTER PROCEDURE Supermercado.mostrarTablaEmpleadoEncriptada --SOLO PARA ADMINS
    @FraseClave NVARCHAR(128)
AS
BEGIN
    -- Manejo de errores
    BEGIN TRY
        -- Seleccionar y desencriptar los datos de la tabla
        SELECT 
            Legajo,
            CONVERT(NVARCHAR(100), DecryptByPassPhrase(@FraseClave, Nombre)) AS Nombre,
            CONVERT(NVARCHAR(100), DecryptByPassPhrase(@FraseClave, Apellido)) AS Apellido,
            CONVERT(INT, DecryptByPassPhrase(@FraseClave, CONVERT(VARBINARY(256), Dni))) AS DNI, --NO ENTIENDO BIEN PQ TENGO QUE CONVERTIRLO CUANDO LO CREE COMO VARBINARY, PERO SI NO ME TIRA ERROR
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
        -- Manejo de errores: imprime el mensaje de error
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



---MOSTRAR REPORTE DE VENTAS 
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

-- Insertar un nuevo producto
EXEC Supermercado.InsertarNuevoProducto 
    @Categoria = 'Alimentos',
    @NombreProducto = 'Pan',
    @PrecioUnitario = 50.00,
    @PrecioUnitarioUsd = 0.25,
    @PrecioReferencia = 45.00,
    @UnidadReferencia = 'Kg';

-- Insertar una nueva factura
EXEC Ventas.InsertarNuevaFactura 
    @nroFactura = '12345',
    @TipoFactura = 'A',
    @FacturaNC = NULL, -- ID de la factura de crédito si aplica
    @Sucursal = 1,
    @Cliente = 1,
    @Producto = 1,
    @Cantidad = 2,
    @Hora = '12:30:00',
    @MedioPago = 'Efectivo',
    @Empleado = 1,
    @IdentificadorPago = 'ABC123';

-- Insertar una nueva sucursal
EXEC Supermercado.InsertarNuevaSucursal 
    @CiudadSucursal = 'Montevideo',
    @DireccionSucursal = 'Av. Principal 1234',
    @Telefono = '099 123 456';

-- Insertar un nuevo cliente
EXEC Supermercado.InsertarNuevoCliente 
    @NombreCliente = 'Juan Perez',
    @CiudadCliente = 'Montevideo',
    @TipoCliente = 'Mayorista',
    @Genero = 'M';

-- Insertar un nuevo empleado
EXEC Supermercado.InsertarNuevoEmpleado 
    @Legajo = 1,
    @NombreEmpleado = 'Ana',
    @Apellido = 'Lopez',
    @Dni = 12345678,
    @Direccion = 'Calle Falsa 123',
    @Email = 'ana.lopez@correo.com',
    @EmailEmpresa = 'ana.lopez@supermercado.com',
    @Cargo = 'Cajero',
    @SucursalID = 1, -- ID de la sucursal
    @Turno = 'Mañana';

-- Insertar un nuevo medio de pago
EXEC Ventas.InsertarNuevoMedioPago 
    @MedioPagoName = 'Efectivo',
    @Descripcion = 'Pago en efectivo';

-- Mostrar el reporte de ventas
EXEC Ventas.MostrarReporteVentas;