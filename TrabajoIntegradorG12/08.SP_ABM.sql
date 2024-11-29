-- Script que crea procedures con consultas comunes, como agregar datos a tablas, actualizar y eliminar
-- El orden de ejecucion es tal cual estan desarrollados

USE Com5600G12;
GO

-- INSERTAR EN TABLA PRODUCTO
CREATE OR ALTER PROCEDURE Supermercado.InsertarNuevoProducto
    @CategoriaID INT,
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
        INSERT INTO Supermercado.Producto (CategoriaID, NombreProducto, PrecioUnitario, PrecioReferencia, UnidadReferencia, Fecha)
        VALUES (@CategoriaID, @NombreProducto, @PrecioUnitario, @PrecioReferencia, @UnidadReferencia, @FechaActual);
    END
    ELSE
    BEGIN
        PRINT 'El producto ya existe o fue borrado';
    END
END;
GO

-- BORRADO LOGICO DE PRODUCTO
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

CREATE OR ALTER PROCEDURE Supermercado.ModificarPrecioProducto
    @NombreProducto VARCHAR(200),
    @NuevoPrecioArs DECIMAL(10, 2) 
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ProductoID INT;
    DECLARE @TipoCambioUsdToArs DECIMAL(10, 4);
    DECLARE @NuevoPrecioUsd DECIMAL(10, 2);


    SELECT @ProductoID = ProductoID
    FROM Supermercado.Producto
    WHERE NombreProducto = @NombreProducto AND deleted_at IS NULL;

    IF @ProductoID IS NULL
    BEGIN
        PRINT 'El producto indicado no existe o está marcado como eliminado.';
        RETURN;
    END;

    EXEC Services.ObtenerTipoCambioUsdToArs @TipoCambioUsdToArs OUTPUT;

    IF @TipoCambioUsdToArs IS NULL OR @TipoCambioUsdToArs = 0
    BEGIN
        PRINT 'Error al obtener el tipo de cambio. Verifique la conexión con el servicio.';
        RETURN;
    END;


    SET @NuevoPrecioUsd = @NuevoPrecioArs / @TipoCambioUsdToArs;

    UPDATE Supermercado.Producto
    SET PrecioUnitario = @NuevoPrecioArs,
        PrecioUnitarioUsd = @NuevoPrecioUsd,
        Fecha = GETDATE()
    WHERE ProductoID = @ProductoID;

    PRINT 'Precio actualizado correctamente.';
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
        PRINT 'La sucursal en esta ciudad y direccion ya existe y no se ha insertado.';
    END
END;
GO

CREATE OR ALTER PROCEDURE Supermercado.CambiarTelefonoSucursal
    @Ciudad VARCHAR(50),        
    @NuevoTelefono VARCHAR(30)  
AS
BEGIN

    IF EXISTS (SELECT 1 FROM Supermercado.Sucursal WHERE Ciudad = @Ciudad)
    BEGIN
        UPDATE Supermercado.Sucursal
        SET Telefono = @NuevoTelefono
        WHERE Ciudad = @Ciudad;

        PRINT 'Teléfono actualizado correctamente.';
    END
    ELSE
    BEGIN
        PRINT 'No se encontró una sucursal en la ciudad especificada.';
    END
END;
GO



-- INSERTAR NUEVO CLIENTE
CREATE OR ALTER PROCEDURE Supermercado.InsertarNuevoCliente
    @TipoCliente VARCHAR(30),
    @Genero CHAR(1)
AS
BEGIN
    INSERT INTO Supermercado.Cliente (TipoCliente, Genero)
    VALUES (@TipoCliente, @Genero);
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

CREATE OR ALTER  PROCEDURE Supermercado.ModificarTurno
    @EmpleadoID INT,
    @NuevoTurno NVARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Supermercado.EmpleadoEncriptado
    SET Turno = @NuevoTurno
    WHERE EmpleadoID = @EmpleadoID;

    IF @@ROWCOUNT = 0
        PRINT 'No se encontró un empleado con el ID especificado.';
    ELSE
        PRINT 'Turno actualizado correctamente.';
END;
GO

CREATE OR ALTER  PROCEDURE Supermercado.ModificarCargo
    @EmpleadoID INT,
    @NuevoCargo NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Supermercado.EmpleadoEncriptado
    SET Cargo = @NuevoCargo
    WHERE EmpleadoID = @EmpleadoID;

    IF @@ROWCOUNT = 0
        PRINT 'No se encontró un empleado con el ID especificado.';
    ELSE
        PRINT 'Cargo actualizado correctamente.';
END;
GO


CREATE OR ALTER PROCEDURE Supervisor.mostrarTablaEmpleadoEncriptada --SOLO PARA Supervisores, hecho con fines didacticos no es necesario
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

--MODIFICO LA DIRECCION, AL ESTAR ENCRIPTADO ME ASEGURO DE USAR LA MISMA CONTRASEÑA ANTERIOR
CREATE OR ALTER PROCEDURE Supervisor.ModificarDireccion
    @EmpleadoID INT,
    @Contrasena NVARCHAR(256),
    @NuevaDireccion NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DireccionActual VARBINARY(256);
    DECLARE @DireccionDesencriptada NVARCHAR(256);
    DECLARE @NuevaDireccionEncriptada VARBINARY(256);

    SELECT @DireccionActual = Direccion
    FROM Supermercado.EmpleadoEncriptado
    WHERE EmpleadoID = @EmpleadoID;

    IF @DireccionActual IS NULL
    BEGIN
        PRINT 'No se encontró un empleado con el ID especificado.';
        RETURN;
    END;

    SET @DireccionDesencriptada = CONVERT(NVARCHAR(256), DecryptByPassPhrase(@Contrasena, @DireccionActual));
	--comparo contra null, ya que en caso de pasar una contraseña incorrecta  @DireccionDesencriptada tendra ese valor
    IF @DireccionDesencriptada IS NULL
    BEGIN
        PRINT 'Contraseña incorrecta. No se puede actualizar la dirección.';
        RETURN;
    END;

    SET @NuevaDireccionEncriptada = EncryptByPassPhrase(@Contrasena, @NuevaDireccion);

    UPDATE Supermercado.EmpleadoEncriptado
    SET Direccion = @NuevaDireccionEncriptada
    WHERE EmpleadoID = @EmpleadoID;

    IF @@ROWCOUNT > 0
        PRINT 'Dirección actualizada correctamente.';
    ELSE
        PRINT 'Error al actualizar la dirección.';
END;
GO



-- INSERTAR NUEVO MEDIO DE PAGO, por consistencia no deberia poder alterar un medio de pago solo insertar
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

-- INSERTAR UNA NUEVA FACTURA
CREATE OR ALTER PROCEDURE Ventas.CrearFactura
    @nroFactura VARCHAR(50),
    @TipoFactura VARCHAR(10),
    @Sucursal INT,
    @Cliente INT,   
    @MedioPago INT,
    @Empleado INT
AS
BEGIN
    DECLARE @Fecha DATETIME;
    DECLARE @Hora TIME;
    SET @Fecha = GETDATE();
    SET @Hora = CONVERT(TIME, GETDATE());
    
    IF NOT EXISTS (SELECT 1 FROM Ventas.Factura WHERE nroFactura = @nroFactura)
    BEGIN
        INSERT INTO Ventas.Factura (
            nroFactura, TipoFactura, sucursalID, clienteID, 
            Fecha, Hora, MedioPago, Empleado)
        VALUES (
            @nroFactura, @TipoFactura, @Sucursal, @Cliente, 
            @Fecha, @Hora, @MedioPago, @Empleado);
    END
    ELSE
    BEGIN
        PRINT 'La factura con este numero ya existe y no se ha insertado.';
    END
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
                PRINT 'El producto ya esta en la factura.';
            END
            ELSE
            BEGIN

                INSERT INTO Ventas.LineaFactura (FacturaID, ProductoID, Cantidad, PrecioU)
                VALUES (@FacturaID, @ProductoID, @Cantidad, @PrecioU);
                PRINT 'Linea de producto creada exitosamente.';
            END
        END
        ELSE
        BEGIN
            PRINT 'La factura o el producto no existen o el producto ha sido eliminado.';
        END
    END TRY
    BEGIN CATCH
        PRINT 'Error al crear la linea de producto:';
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
        -- Verifica si la factura existe y su IdentificadorPago contiene '--' utilizando LIKE
        IF EXISTS (SELECT 1 
                   FROM Ventas.Factura f
                   WHERE f.IDFactura = @IDFactura AND f.IdentificadorPago LIKE '%--%')
        BEGIN
            -- Actualiza el identificador de pago
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
        -- Captura errores y los muestra
        PRINT 'Error al pagar la factura:';
        PRINT ERROR_MESSAGE();
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE Ventas.CrearNotaDeCredito
    @FacturaID INT,          -- ID de la factura
    @LineaFacturaID INT      -- ID de la línea de factura
AS
BEGIN
    BEGIN TRY
        -- Inicia la transacción
        BEGIN TRANSACTION;

        -- Verifica si la factura existe y no está pagada
        IF EXISTS (
            SELECT 1 
            FROM Ventas.Factura 
            WHERE IDFactura = @FacturaID 
              AND IdentificadorPago LIKE '%--%'
        )
        BEGIN
            -- Verifica que la línea de factura exista y esté asociada a la factura
            IF EXISTS (
                SELECT 1 
                FROM Ventas.LineaFactura 
                WHERE IDLineaFactura = @LineaFacturaID 
                  AND FacturaID = @FacturaID
            )
            BEGIN
                -- Obtener los detalles de la línea de factura
                DECLARE @ProductoID INT;
                DECLARE @Cantidad INT;
                DECLARE @PrecioU DECIMAL(10, 2);

                SELECT 
                    @ProductoID = ProductoID, 
                    @Cantidad = Cantidad, 
                    @PrecioU = PrecioU
                FROM Ventas.LineaFactura
                WHERE IDLineaFactura = @LineaFacturaID;

                -- Insertar la nota de crédito (línea NDC)
                INSERT INTO Ventas.LineaNDC (
                    Cantidad, ProductoID, FacturaID, LineaFacturaID, PrecioU
                )
                VALUES (
                    @Cantidad, @ProductoID, @FacturaID, @LineaFacturaID, @PrecioU
                );

                PRINT 'Nota de crédito creada exitosamente.';
            END
            ELSE
            BEGIN
                -- La línea de factura no existe o no pertenece a la factura
                PRINT 'Error: La línea de factura no existe o no está asociada a la factura indicada.';
                ROLLBACK TRANSACTION;
                RETURN;
            END
        END
        ELSE
        BEGIN
            -- La factura no existe o ya está pagada
            PRINT 'Error: La factura no existe o ya está pagada.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Confirma la transacción
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Manejo de errores
        PRINT 'Error al crear la nota de crédito:';
        PRINT ERROR_MESSAGE();
        ROLLBACK TRANSACTION;
    END CATCH
END;
GO


--Mostrar reporte de ventas
CREATE OR ALTER PROCEDURE Ventas.MostrarReporteVentas
AS
BEGIN
    SELECT
        f.IDFactura AS [ID FACTURA],
        f.TipoFactura AS [TIPO DE FACTURA],
        s.Ciudad AS [CIUDAD],
        c.TipoCliente AS [TIPO DE CLIENTE],
        c.Genero AS [GENERO],
        cat.Descripcion AS [LINEA DE PRODUCTO],
        p.NombreProducto AS [PRODUCTO],
        p.PrecioUnitario AS [PRECIO UNITARIO],
        l.Cantidad AS [CANTIDAD],
        f.Fecha AS [FECHA],
        mp.Descripcion AS [MEDIO DE PAGO],
        e.Legajo AS [EMPLEADO],
        s.Ciudad AS [SUCURSAL]
    FROM 
        Ventas.Factura f
    JOIN
        Ventas.LineaFactura l ON l.FacturaID = f.IDFactura
    JOIN 
        Supermercado.Cliente c ON f.clienteID = c.ClienteID
    JOIN 
        Supermercado.Producto p ON l.ProductoID = p.ProductoID
    JOIN 
        Ventas.MediosPago mp ON f.MedioPago = mp.IdMedioPago
    JOIN 
        Supermercado.EmpleadoEncriptado e ON f.Empleado = e.EmpleadoID
    JOIN 
        Supermercado.Sucursal s ON f.sucursalID = s.SucursalID
    JOIN
        Supermercado.Categoria cat ON p.CategoriaID = cat.ID;
END;
GO


