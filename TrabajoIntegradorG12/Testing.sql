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
EXEC Supermercado.InsertarSucursales 'C:\Users\Usuario\Desktop\BaseDeDatosG12\Informacion_complementaria.xlsx'
GO
--5
EXEC Supervisor.InsertarEmpleadosEncriptado 'C:\Users\Usuario\Desktop\BaseDeDatosG12\Informacion_complementaria.xlsx','contraseña'
GO

--6
EXEC Supermercado.InsertarCategorias 'C:\Users\Usuario\Desktop\BaseDeDatosG12\Informacion_complementaria.xlsx'
GO

--7
EXEC Ventas.InsertarMediosPago 'C:\Users\Usuario\Desktop\BaseDeDatosG12\Informacion_complementaria.xlsx'
GO

--8 (Ejecutar en cualquier orden y tener en cuenta la ruta de los archivos)
EXEC Supermercado.InsertarProductosCatalogo 'C:\Users\Usuario\Desktop\BaseDeDatosG12\Productos\catalogo.csv'
GO

EXEC Supermercado.InsertarProductosElectronicos 'C:\Users\Usuario\Desktop\BaseDeDatosG12\Productos\Electronic accessories.xlsx'
GO

EXEC Supermercado.InsertarProductosImportados'C:\Users\Usuario\Desktop\BaseDeDatosG12\Productos\Productos_importados.xlsx'
GO


--9 Importacion de facturas
EXEC Ventas.InsertarEnTablaFacturas 'C:\Users\Usuario\Desktop\BaseDeDatosG12\Ventas_registradas.csv'
GO

--10 Scripts varios y comunes (ejecutar en cualquier orden)

--ingresando como al sistema como empleado se espera error de permisos, si ejecuta como supervisor es exitoso--
EXEC Supervisor.ModificarDireccion 
    @EmpleadoID = 1, 
    @Contrasena = 'contraseña', 
    @NuevaDireccion = '789 Calle Falsa, Ciudad';

--ejecutando como supervisor, pero la contraseña enviada es incorrecta
EXEC Supervisor.ModificarDireccion 
    @EmpleadoID = 1, 
    @Contrasena = 'ClaveIncorrecta', 
    @NuevaDireccion = '789 Calle Falsa, Ciudad';

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

-- Modifico el turno de un empleado
EXEC Supermercado.ModificarTurno @EmpleadoID = 1, @NuevoTurno = 'Mañana';


--modifico el cargo de un empleado
EXEC Supermercado.ModificarCargo @EmpleadoID = 1, @NuevoCargo = 'gerente';

--modifico la direccion de un empleado con la contraseña correcta
EXEC Supervisor.ModificarDireccion 
    @EmpleadoID = 1, 
    @Contrasena = 'MiClaveSegura123', 
    @NuevaDireccion = '456 Calle Actualizada, Ciudad';

-- modifico la direccion de un empleado con una contraseña incorrecta
EXEC Supervisor.ModificarDireccion 
    @EmpleadoID = 1, 
    @Contrasena = 'ClaveIncorrecta', 
    @NuevaDireccion = '789 Calle Falsa, Ciudad';

-- -----------------------------------------------------
-- Insertar una nueva sucursal
EXEC Supermercado.InsertarNuevaSucursal 
    @CiudadSucursal = 'Montevideo',
    @DireccionSucursal = 'Av. Principal 1234',
    @Telefono = '099 123 456',
    @Horario = 'L a V 8 a. m.–8 p. m';

EXEC Supermercado.CambiarTelefonoSucursal
    @Ciudad = 'Montevideo',
    @NuevoTelefono = '123-456-789';
-- -----------------------------------------------------

-- Insertar una nueva factura
EXEC Ventas.CrearFactura
    @nroFactura = '12345',
    @TipoFactura = 'A',
    @Sucursal = 1,
    @Cliente = 1,
    @Hora = '12:30:00',
    @MedioPago = 1,  
    @Empleado = 1;



-- Insertar un nuevo producto
EXEC Supermercado.InsertarNuevoProducto
    @Categoria = 'Alimentos',
    @NombreProducto = 'Pan',
    @PrecioUnitario = 50.00,
    @PrecioUnitarioUsd = 0.25,
    @PrecioReferencia = 45.00,
    @UnidadReferencia = 'Kg';

-- Insertar un nuevo producto erroneo
EXEC Supermercado.InsertarNuevoProducto
    @NombreProducto = 'Pan',
    @PrecioUnitario = 50.00,
    @PrecioUnitarioUsd = 0.25,
    @PrecioReferencia = 45.00,
    @UnidadReferencia = 'Kg';

--Borrado logico de producto
EXEC Supermercado.EliminarProducto @ProductoID = 1;


--Crear linea de factura
EXEC Ventas.CrearLineaFactura @FacturaID = 1, @ProductoID = 1, @Cantidad = 5, @PrecioU = 150.00;

--Crear linea de factura inexistente
EXEC Ventas.CrearLineaFactura @FacturaID = 9999, @ProductoID = 1, @Cantidad = 5, @PrecioU = 150.00;

-- Pagar factura
EXEC Ventas.PagarFactura @IDFactura = 3347, @IdentificadorPago = 'ABCD1234';

--Muestras correctamente el reporte
EXEC Ventas.MostrarReporteVentas;


--EJECUCION REPORTE XML (ejecutar de uno a la vez)
EXEC Reporte.ReporteFacturadoPorDiaXML 3,2019;

EXEC Reporte.ReporteFacturadoPorTurnoTrimestralXML 2019,1;

EXEC Reporte.ReporteTop5ProductosPorSemanaXML 3,2019;

EXEC Reporte.ReporteMenosVendidosPorMesXML 3,2019;

EXEC Reporte.ReporteVentasPorCiudadPorRangoDeFechasXML'2019-3-01','2019-3-31';        

EXEC Reporte.ReporteVentasPorSucursalYFechaXML '2019-3-01','Ramos mejia'
