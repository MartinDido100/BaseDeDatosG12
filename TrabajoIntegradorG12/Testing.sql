-- Este archivo es un archivo de testing que se encarga de ejecutar todos los procedures creados
-- anteriormente, ejecutar en el orden indicado

--1
USE Com5600G12;
GO

--2
-- Crear login para 'martin'
CREATE LOGIN martin WITH PASSWORD = 'tincho32';

-- Crear el usuario 'martin' en la base de datos 'Com5600G12'
CREATE USER martin FOR LOGIN martin;

--Crear roles siendo supervisor
EXEC Supervisor.CrearRolesConPermisos;

-- Asignar el rol 'Supervisor' al usuario 'martin'
EXEC sp_addrolemember 'Empleado', 'martin';

--3 Execs para crear un par de logins adicionales
EXEC Supermercado.CrearLoginUserEmpleado 'soymessi','contraseña'
EXEC Supervisor.CrearLoginUserSupervisor 'mbappe','contraseña'

--4 (Ejecutar en cualquier orden y tener en cuenta la ruta de los archivos)
EXEC Supermercado.InsertarSucursales 'C:\Users\Usuario\Desktop\BaseDeDATOG12\BaseDeDatosG12\Informacion_complementaria.xlsx'
GO

EXEC Supermercado.InsertarEmpleados 'C:\Users\Usuario\Desktop\BaseDeDATOG12\BaseDeDatosG12\Informacion_complementaria.xlsx'
GO

EXEC Supervisor.InsertarEmpleadosEncriptado 'C:\Users\Usuario\Desktop\BaseDeDATOG12\BaseDeDatosG12\Informacion_complementaria.xlsx','contraseña'
GO

EXEC Ventas.InsertarMediosPago 'C:\Users\Usuario\Desktop\BaseDeDATOG12\BaseDeDatosG12\Informacion_complementaria.xlsx'
GO

--5 (Ejecutar en cualquier orden y tener en cuenta la ruta de los archivos)
EXEC Supermercado.InsertarProductosCatalogo 'C:\Users\Usuario\Desktop\BaseDeDATOG12\BaseDeDatosG12\Productos\catalogo.csv'
GO

EXEC Supermercado.InsertarProductosElectronicos 'C:\Users\Usuario\Desktop\BaseDeDATOG12\BaseDeDatosG12\Productos\Electronic accessories.xlsx'
GO

EXEC Supermercado.InsertarProductosImportados'C:\Users\Usuario\Desktop\BaseDeDATOG12\BaseDeDatosG12\Productos\Productos_importados.xlsx'
GO

-- Insertar un nuevo cliente
EXEC Supermercado.InsertarNuevoCliente 
    @NombreCliente = 'Juan Perez',
    @CiudadCliente = 'Montevideo',
    @TipoCliente = 'Mayorista',
    @Genero = 'M';

SELECT * FROM Supermercado.Cliente

--6 Importacion de facturas
EXEC Ventas.InsertarEnTablaFacturas 'C:\Users\Usuario\Desktop\BaseDeDATOG12\BaseDeDatosG12\Ventas_registradas.csv'
GO

--7 Generar nota de credito (Cambiar el ID de factura en caso de necesitarse)
--Factura pagada y habilitada para nota de credito
EXEC Supervisor.GenerarNotaDeCredito 775;

--Factura no pagada y habilitada para nota de credito
EXEC Supervisor.GenerarNotaDeCredito 774;



--8 Scripts varios y comunes (ejecutar en cualquier orden)

-- Insertar un nuevo medio de pago
EXEC Ventas.InsertarNuevoMedioPago 
    @MedioPagoName = 'CRYPTO',
    @Descripcion = 'Pago en criptomonedas';

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


-- Insertar una nueva sucursal
EXEC Supermercado.InsertarNuevaSucursal 
    @CiudadSucursal = 'Montevideo',
    @DireccionSucursal = 'Av. Principal 1234',
    @Telefono = '099 123 456',
    @Horario = 'Lunes a Viernes de 9:00 a 18:00';

-- Insertar una nueva factura
EXEC Ventas.CrearFactura
    @nroFactura = '12345',
    @TipoFactura = 'A',
    @Sucursal = 1,
    @Cliente = 1,
    @Hora = '12:30:00',
    @MedioPago = 1,  -- Aquí, el MedioPago debe ser un número, no una cadena (como se define en el procedimiento)
    @Empleado = 1;

-- Insertar un nuevo producto
EXEC Supermercado.InsertarNuevoProducto
    @Categoria = 'Alimentos',
    @NombreProducto = 'Pan',
    @PrecioUnitario = 50.00,
    @PrecioUnitarioUsd = 0.25,
    @PrecioReferencia = 45.00,
    @UnidadReferencia = 'Kg';

--Borrado logico de producto
EXEC Supermercado.EliminarProducto @ProductoID = 1;

--Crear linea de factura
EXEC Ventas.CrearLineaFactura @FacturaID = 3347, @ProductoID = 1, @Cantidad = 5, @Subtotal = 150.00;

--Crear linea de factura erronea
EXEC Ventas.CrearLineaFactura @FacturaID = 9999, @ProductoID = 1, @Cantidad = 5, @Subtotal = 150.00;

-- Pagar factura
EXEC Ventas.PagarFactura @IDFactura = 3347, @IdentificadorPago = 'ABCD1234';
