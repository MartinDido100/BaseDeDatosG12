USE Comercio;
GO

--ESTE ARCHIVO DIDACTICO, NO ESTARIA EN LA ENTREGA AL CLIENTE


--necesito mostrar
--Factura ID, Tipo de factura, Ciudad, Tipo de cliente, Genero, Linea de producto, Precio unitario, Cantidad, Total, Fecha, Hora, Medio de pago

--INSERTAMOS PRODUCTOS
EXEC Supermercado.InsertarEnTablaProducto 'C:\Users\Usuario\Desktop\Com5600_Grupo12_Entrega03\Productos\catalogo.csv';
--SELECT * from Supermercado.Producto



exec Supermercado.InsertarEnTablaVentas 'C:\Users\Usuario\Desktop\Com5600_Grupo12_Entrega03\Ventas_registradas.csv';
--SELECT *from Supermercado.Venta



--cantidad de productos
select count(*) productos
from Supermercado.Producto

select  *
from Supermercado.Producto

--cantidad de ventas
select count(*) ventas
from Supermercado.Venta

select * 
from Supermercado.Venta

--productos repetidos por ejemplo  Cerveza Clásica Steinburg
SELECT *from Supermercado.Producto
where NombreProducto like 'Cerveza Clásica Steinburg'

--MUESTRO TODOS LOS PRODUCTOS QUE APARECEN UNA SOLA VEZ EN VENTAS 
SELECT 
    P.ProductoID, 
    P.NombreProducto,
    P.Categoria,
    P.PrecioUnitario,
    P.PrecioReferencia,
    P.UnidadReferencia,
    P.Fecha,
    COUNT(*) AS Cantidad
FROM 
    Supermercado.Producto P
INNER JOIN 
    Supermercado.Venta V 
ON 
    P.NombreProducto LIKE V.Producto 
    AND P.PrecioUnitario = V.PrecioUnitario 
GROUP BY 
    P.ProductoID,   
    P.NombreProducto, 
    P.Categoria, 
    P.PrecioUnitario, 
    P.PrecioReferencia, 
    P.UnidadReferencia, 
    P.Fecha

--MUESTRO TODOS LO PRODUCTOS EN VENTAS QUE TIENEN VARIAS APARICIONES, lo haria con la tabla productos per elimine duplicados

SELECT Producto, COUNT(*) AS Cantidad
FROM Supermercado.Venta
GROUP BY Producto
HAVING COUNT(*) > 1;

