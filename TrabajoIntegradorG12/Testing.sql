-- Este archivo es un archivo de testing que se encarga de ejecutar todos los procedures creados
-- anteriormente, ejecutar en el orden indicado

--1
USE Com5600G12;
GO

--2
--Crear roles siendo supervisor
EXEC Supervisor.CrearRolesConPermisos;

--3 Execs para crear un par de logins adicionales
EXEC Supermercado.CrearLoginUserEmpleado 'soymessi','contraseña'
EXEC Supervisor.CrearLoginUserSupervisor 'mbappe','contraseña'

--IMPORTACION DE ARCHIVOS
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
--

--9 Importacion de facturas
EXEC Ventas.InsertarEnTablaFacturas 'C:\Users\Usuario\Desktop\BaseDeDatosG12\Ventas_registradas.csv'
GO

--10 Scripts varios y comunes (ejecutar en cualquier orden)

--ingresando como al sistema como empleado se espera error de permisos, si ejecuta como supervisor es exitoso--
EXEC Supervisor.ModificarDireccion 
    @EmpleadoID = 1, 
    @Contrasena = 'contraseña', 
    @NuevaDireccion = '789 Calle Falsa, Ciudad';

--ejecutando como supervisor, pero la contraseña enviada es incorrecta, SE ESPERA ERROR
EXEC Supervisor.ModificarDireccion 
    @EmpleadoID = 1, 
    @Contrasena = 'ClaveIncorrecta', 
    @NuevaDireccion = '789 Calle Falsa, Ciudad';

-- Insertar un nuevo medio de pago
EXEC Ventas.InsertarNuevoMedioPago 
    @MedioPagoName = 'CRYPTO',
    @Descripcion = 'Pago en criptomonedas';

-- Modifico el turno de un empleado
EXEC Supermercado.ModificarTurno @EmpleadoID = 1, @NuevoTurno = 'Mañana';
SELECT * FROM Supermercado.EmpleadoEncriptado e
WHERE e.EmpleadoID = 1

--modifico el cargo de un empleado
EXEC Supermercado.ModificarCargo @EmpleadoID = 1, @NuevoCargo = 'gerente';
SELECT * FROM Supermercado.EmpleadoEncriptado e
WHERE e.EmpleadoID = 1

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

SELECT * FROM Supermercado.Sucursal
-- -----------------------------------------------------
-- Insertar una nueva factura
EXEC Ventas.CrearFactura
    @nroFactura = '123415',
    @TipoFactura = 'A',
    @Sucursal = 1,
    @Cliente = 1,
    @MedioPago = 1,  
    @Empleado = 1;

-----------------------------------------------------------

--Crear linea de factura
EXEC Ventas.CrearLineaFactura @FacturaID = 1, @ProductoID = 1, @Cantidad = 5, @PrecioU = 150.00;

--Crear linea de factura inexistente (id incorrecto), SE ESPERA ERROR
EXEC Ventas.CrearLineaFactura @FacturaID = 9999, @ProductoID = 1, @Cantidad = 5, @PrecioU = 150.00;

-- Pagar factura impaga
EXEC Ventas.PagarFactura @IDFactura = 15, @IdentificadorPago = 'ABCD1234';
SELECT * FROM Ventas.Factura f
WHERE f.IDFactura = 15

--pagar factura ya pagada, se espera error
EXEC Ventas.PagarFactura @IDFactura = 1, @IdentificadorPago = 'ABCD1234';

--genero nota de credito exitosa
exec Ventas.CrearNotaDeCredito @FacturaID = 12, @LineaFacturaID = 12;

--generar una nota de credito a una factura ya pagada, SE ESPERA ERROR
exec Ventas.CrearNotaDeCredito @FacturaID = 1, @LineaFacturaID = 1;

--generar una ndc para una factura valida, pero una linea incorrecta, SE ESPERA ERROR
exec Ventas.CrearNotaDeCredito @FacturaID = 26, @LineaFacturaID = 5;


--Muestras correctamente el reporte
EXEC Ventas.MostrarReporteVentas;


--------------------EJECUTAR UNO SEGUIDO DEL OTRO-------------------------------
-- Insertar un nuevo producto
EXEC Supermercado.InsertarNuevoProducto
    @CategoriaID = 1, 
    @NombreProducto = 'Pan',
    @PrecioUnitario = 50.00,
    @PrecioUnitarioUsd = 0.25,
    @PrecioReferencia = 45.00,
    @UnidadReferencia = 'Kg';


-- Insertar un nuevo producto Repetido, SE ESPERA ERROR
EXEC Supermercado.InsertarNuevoProducto
    @CategoriaID = 1,  
    @NombreProducto = 'Pan',
    @PrecioUnitario = 50.00,
    @PrecioUnitarioUsd = 0.25,
    @PrecioReferencia = 45.00,
    @UnidadReferencia = 'Kg';
-------------------------------------------------------------------------------

--Borrado logico de producto
EXEC Supermercado.EliminarProducto @ProductoID = 1;
SELECT * FROM Supermercado.Producto p
WHERE p.ProductoID = 1

--EJECUCION REPORTE XML (ejecutar de uno a la vez)
EXEC Reporte.ReporteFacturadoPorDiaXML 3,2019;

EXEC Reporte.ReporteFacturadoPorTurnoTrimestralXML 2019,1;

EXEC Reporte.ReporteTop5ProductosPorSemanaXML 3,2019;

EXEC Reporte.ReporteMenosVendidosPorMesXML 3,2019;

EXEC Reporte.ReporteVentasPorCiudadPorRangoDeFechasXML'2019-3-01','2019-3-31';        

EXEC Reporte.ReporteVentasPorSucursalYFechaXML '2019-3-01','Ramos mejia'
