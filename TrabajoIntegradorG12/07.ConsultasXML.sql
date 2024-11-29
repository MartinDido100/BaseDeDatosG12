USE Com5600G12;
GO

--Mensual: ingresando un mes y a�o determinado mostrar el total facturado por d�as de 
--la semana, incluyendo s�bado y domingo. 
CREATE OR ALTER PROCEDURE Reporte.ReporteFacturadoPorDiaXML
    @Mes INT,
    @Anio INT
AS
BEGIN


    DECLARE @XMLResult XML;


    SELECT 
        DATENAME(WEEKDAY, f.Fecha) AS "DiaSemana",         
        DATEPART(WEEKDAY, f.Fecha) AS "NumeroDiaSemana",   
        SUM(l.PrecioU * l.Cantidad) AS "TotalFacturado"
    INTO #TempReport
    FROM 
        Ventas.Factura f
    JOIN 
        Ventas.LineaFactura l ON f.IDFactura = l.FacturaID
    WHERE 
        MONTH(f.Fecha) = @Mes
        AND YEAR(f.Fecha) = @Anio
    GROUP BY 
        DATENAME(WEEKDAY, f.Fecha),
        DATEPART(WEEKDAY, f.Fecha)
    ORDER BY 
        DATEPART(WEEKDAY, f.Fecha); -- DATEPART devuelve el dia de la semana para la fecha

    SELECT @XMLResult = 
        (SELECT 
            DiaSemana,
            NumeroDiaSemana,
            TotalFacturado
        FROM #TempReport
        FOR XML PATH('Dia'), ROOT('ReporteFacturacion'));


    SELECT @XMLResult AS XMLResult;
	DROP TABLE #TempReport;
END;
GO


--Trimestral: mostrar el total facturado por turnos de trabajo por mes. 
CREATE OR ALTER PROCEDURE Reporte.ReporteFacturadoPorTurnoTrimestralXML
    @Anio INT,          
    @Trimestre INT      -- Trimestre (1, 2, 3, 4)
AS
BEGIN
    SET NOCOUNT ON;

-- solo hay 4 trimestres
    IF @Trimestre < 1 OR @Trimestre > 4
    BEGIN
        RAISERROR('El trimestre debe ser un valor entre 1 y 4.', 16, 1);
        RETURN;
    END;

    DECLARE @MesInicio INT, @MesFin INT;

    IF @Trimestre = 1
    BEGIN
        SET @MesInicio = 1;
        SET @MesFin = 3;
    END;

    IF @Trimestre = 2
    BEGIN
        SET @MesInicio = 4;
        SET @MesFin = 6;
    END;

    IF @Trimestre = 3
    BEGIN
        SET @MesInicio = 7;
        SET @MesFin = 9;
    END;

    IF @Trimestre = 4
    BEGIN
        SET @MesInicio = 10;
        SET @MesFin = 12;
    END;

    DECLARE @XMLResult XML;

	--DATEPART(HOUR, f.Hora) devuelve solo la hora del horario
    SELECT 
        MONTH(f.Fecha) AS Mes,
        CASE 
            WHEN DATEPART(HOUR, f.Hora) >= 8 AND DATEPART(HOUR, f.Hora) < 15 THEN 'Turno Ma�ana'
            WHEN DATEPART(HOUR, f.Hora) >= 15 AND DATEPART(HOUR, f.Hora) < 21 THEN 'Turno Tarde'
            ELSE 'Fuera de Turno'
        END AS Turno,
        SUM(l.PrecioU * l.Cantidad) AS TotalFacturado
    INTO #TempReport
    FROM 
        Ventas.Factura f
    JOIN 
        Ventas.LineaFactura l ON f.IDFactura = l.FacturaID
    WHERE 
        YEAR(f.Fecha) = @Anio
        AND MONTH(f.Fecha) BETWEEN @MesInicio AND @MesFin
    GROUP BY 
        MONTH(f.Fecha),
        CASE --asigno turno segun el horario
            WHEN DATEPART(HOUR, f.Hora) >= 8 AND DATEPART(HOUR, f.Hora) < 15 THEN 'Turno Ma�ana'
            WHEN DATEPART(HOUR, f.Hora) >= 15 AND DATEPART(HOUR, f.Hora) < 21 THEN 'Turno Tarde'
            ELSE 'Fuera de Turno'
        END
    ORDER BY 
        Mes, Turno;

    SELECT @XMLResult = 
        (SELECT 
            Mes,
            Turno,
            TotalFacturado
        FROM #TempReport
        FOR XML PATH('TurnoFactura'), ROOT('ReporteFacturacionTrimestral'));


    SELECT @XMLResult AS XMLResult;


    DROP TABLE #TempReport;
END;
GO



--por rango de fechas: ingresando un rango de fechas a demanda, debe poder mostrar 
--la cantidad de productos vendidos en ese rango por sucursal, ordenado de mayor a 
--menor. 
CREATE OR ALTER PROCEDURE Reporte.ReporteVentasPorCiudadPorRangoDeFechasXML
    @FechaInicio DATE,    
    @FechaFin DATE        
AS
BEGIN
    SET NOCOUNT ON;

    IF @FechaInicio > @FechaFin
    BEGIN
        THROW 50003, 'La fecha de inicio no puede ser mayor que la fecha de fin.', 1;
    END;


    DECLARE @XMLResult XML;

    
    ;WITH VentasPorCiudad AS (
        SELECT 
            f.sucursalID,
            s.Ciudad,  
            SUM(l.Cantidad) AS TotalVendidos
        FROM 
            Ventas.LineaFactura l
        JOIN 
            Ventas.Factura f ON l.FacturaID = f.IDFactura
        JOIN 
            Supermercado.Sucursal s ON f.sucursalID = s.SucursalID
        WHERE 
            f.Fecha BETWEEN @FechaInicio AND @FechaFin
        GROUP BY 
            f.sucursalID, s.Ciudad
    )


    SELECT @XMLResult = (
        SELECT 
            Ciudad,
            TotalVendidos
        FROM 
            VentasPorCiudad
        ORDER BY 
            TotalVendidos DESC
        FOR XML PATH('CiudadVenta'), ROOT('ReporteVentasPorCiudad')
    );

 
    SELECT @XMLResult AS XMLResult;
END;
GO


--Mostrar los 5 productos m�s vendidos en un mes, por semana 
CREATE OR ALTER PROCEDURE Reporte.ReporteTop5ProductosPorSemanaXML
    @Mes INT,        
    @Anio INT        
AS
BEGIN
    SET NOCOUNT ON;

    -- solo hay 12 meses
    IF @Mes < 1 OR @Mes > 12
    BEGIN
        THROW 50002, 'El mes ingresado es inv�lido. Debe ser un valor entre 1 y 12.', 1;
    END;


    DECLARE @XMLResult XML;

    ;WITH ProductosPorSemana AS (
        SELECT 
            p.NombreProducto,
            DATEPART(WEEK, f.Fecha) AS Semana,          -- N�mero de semana en el mes
            SUM(l.Cantidad) AS TotalVendidos
        FROM 
            Ventas.LineaFactura l
        JOIN 
            Supermercado.Producto p ON l.ProductoID = p.ProductoID
        JOIN 
            Ventas.Factura f ON l.FacturaID = f.IDFactura
        WHERE 
            f.Fecha BETWEEN DATEFROMPARTS(@Anio, @Mes, 1) AND EOMONTH(DATEFROMPARTS(@Anio, @Mes, 1))
        GROUP BY 
            p.NombreProducto, DATEPART(WEEK, f.Fecha)
    )

    -- obtengo de los 5 productos m�s vendidos 
    SELECT @XMLResult = (
        SELECT 
            Semana, 
            NombreProducto,
            TotalVendidos
        FROM (
            SELECT 
                Semana,
                NombreProducto,
                TotalVendidos,
                ROW_NUMBER() OVER (PARTITION BY Semana ORDER BY TotalVendidos DESC) AS Rnk
            FROM 
                ProductosPorSemana
        ) AS RankedProductos
        WHERE Rnk <= 5
        ORDER BY Semana, Rnk
        FOR XML PATH('ProductoSemana'), ROOT('ReporteTop5ProductosPorSemana')
    );


    SELECT @XMLResult AS XMLResult;
END;
GO




--Mostrar los 5 productos menos vendidos en un mes, por semana 
CREATE OR ALTER PROCEDURE Reporte.ReporteMenosVendidosPorMesXML
    @Mes INT,        
    @Anio INT        
AS
BEGIN

    SET NOCOUNT ON;
    IF @Mes < 1 OR @Mes > 12
    BEGIN
        THROW 50002, 'El mes ingresado es invalido. Debe ser un valor entre 1 y 12.', 1;
    END;


    DECLARE @XMLResult XML;

    -- Consulta para obtener los 5 productos menos vendidos en el mes
    ;WITH ProductosPorMes AS (
        SELECT 
            p.NombreProducto,
            SUM(l.Cantidad) AS TotalVendidos
        FROM 
            Ventas.LineaFactura l
        JOIN 
            Supermercado.Producto p ON l.ProductoID = p.ProductoID
        JOIN 
            Ventas.Factura f ON l.FacturaID = f.IDFactura
        WHERE 
            f.Fecha BETWEEN DATEFROMPARTS(@Anio, @Mes, 1) AND EOMONTH(DATEFROMPARTS(@Anio, @Mes, 1))
        GROUP BY 
            p.NombreProducto
    )

    -- Selecci�n de los 5 productos menos vendidos, ordenado por la cantidad vendida
    SELECT @XMLResult = (
        SELECT 
            NombreProducto,
            TotalVendidos
        FROM (
            SELECT 
                NombreProducto,
                TotalVendidos,
                ROW_NUMBER() OVER (ORDER BY TotalVendidos ASC) AS Rnk
            FROM 
                ProductosPorMes
        ) AS RankedProductos
        WHERE Rnk <= 5
        ORDER BY TotalVendidos ASC
        FOR XML PATH('ProductoMenosVendido'), ROOT('ReporteMenosVendidosPorMes')
    );


    SELECT @XMLResult AS XMLResult;
END;
GO


--Mostrar total acumulado de ventas (o sea tambien mostrar el detalle) para una fecha 
--y sucursal particulares
CREATE OR ALTER PROCEDURE Reporte.ReporteVentasPorSucursalYFechaXML
    @Fecha DATE,           
    @SucursalNombre NVARCHAR(100)  
AS
BEGIN
    SET NOCOUNT ON;


    DECLARE @TotalDia DECIMAL(10, 2) = 0;
    DECLARE @XMLResult XML;

    CREATE TABLE #VentasDetalle (
        FacturaID INT,
        NombreProducto NVARCHAR(200),
        Cantidad INT,
        PrecioUnitario DECIMAL(10, 2),
        Subtotal DECIMAL(10, 2),
        TotalVenta DECIMAL(10, 2)
    );

	
    INSERT INTO #VentasDetalle (FacturaID, NombreProducto, Cantidad, PrecioUnitario, Subtotal, TotalVenta)
    SELECT 
        f.IDFactura,                      
        p.NombreProducto,                  
        l.Cantidad,                        
        p.PrecioUnitario,                  
        l.Cantidad * p.PrecioUnitario AS Subtotal, 
        (SELECT SUM(l2.Cantidad * p2.PrecioUnitario) 
            FROM Ventas.LineaFactura l2 
            JOIN Supermercado.Producto p2 ON l2.ProductoID = p2.ProductoID 
            WHERE l2.FacturaID = f.IDFactura) AS TotalVenta 
    FROM 
        Ventas.LineaFactura l
    JOIN 
        Ventas.Factura f ON l.FacturaID = f.IDFactura
    JOIN 
        Supermercado.Producto p ON l.ProductoID = p.ProductoID
    JOIN 
        Supermercado.Sucursal s ON f.sucursalID = s.SucursalID
    WHERE 
        f.Fecha = @Fecha                       
        AND s.Ciudad = @SucursalNombre           

    SELECT @TotalDia = SUM(TotalVenta) FROM #VentasDetalle;

    -- creo el primer xml
    SELECT @XMLResult = (
        SELECT 
            FacturaID,
            NombreProducto, 
            Cantidad, 
            PrecioUnitario, 
            Subtotal, 
            TotalVenta
        FROM 
            #VentasDetalle
        ORDER BY 
            FacturaID, NombreProducto
        FOR XML PATH('VentaDetalle'), ROOT('ReporteVentasSucursal')
    );

    -- Crear EL XML del total  por separado, para dejarlo al final
    DECLARE @TotalDiaXML XML;
    SET @TotalDiaXML = (
        SELECT @TotalDia AS TotalDelDia
        FOR XML PATH('TotalDelDia')
    );

    -- Concateno los 2 XML
    SET @XMLResult = (
        SELECT 
            (SELECT 
                FacturaID,
                NombreProducto, 
                Cantidad, 
                PrecioUnitario, 
                Subtotal, 
                TotalVenta
            FROM 
                #VentasDetalle
            ORDER BY 
                FacturaID, NombreProducto
            FOR XML PATH('VentaDetalle'), TYPE) AS VentaDetalles,
            @TotalDiaXML AS TotalDia
        FOR XML PATH('ReporteVentasSucursal')
    );

    SELECT @XMLResult AS ReporteXML;

    DROP TABLE IF EXISTS #VentasDetalle;
END;
GO

