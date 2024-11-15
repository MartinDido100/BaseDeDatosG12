USE Com5600G12;
GO

CREATE OR ALTER PROCEDURE Reporte.ReporteFacturadoPorDiaXML
    @Mes INT,
    @Anio INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        DATENAME(WEEKDAY, f.Fecha) AS "DiaSemana",         -- Nombre del día
        DATEPART(WEEKDAY, f.Fecha) AS "NumeroDiaSemana",   -- Número del día para ordenar
        SUM(l.Subtotal) AS "TotalFacturado"
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
        DATEPART(WEEKDAY, f.Fecha) -- Ordenar por el número del día de la semana
    FOR XML PATH('Dia'), ROOT('ReporteFacturacion');
END;
GO

--Trimestral: mostrar el total facturado por turnos de trabajo por meS----
CREATE OR ALTER PROCEDURE Reporte.ReporteFacturadoPorTurnoTrimestralXML
    @Anio INT,          -- Año para el trimestre
    @Trimestre INT      -- Trimestre (1, 2, 3, 4)
AS
BEGIN
    SET NOCOUNT ON;

    -- Validación para asegurarse de que el trimestre esté en el rango correcto
    IF @Trimestre < 1 OR @Trimestre > 4
    BEGIN
        RAISERROR('El trimestre debe ser un valor entre 1 y 4.', 16, 1);
        RETURN;
    END

    -- Determinamos el rango de meses según el trimestre
    DECLARE @MesInicio INT, @MesFin INT;

    IF @Trimestre = 1
    BEGIN
        SET @MesInicio = 1;
        SET @MesFin = 3;
    END
    ELSE IF @Trimestre = 2
    BEGIN
        SET @MesInicio = 4;
        SET @MesFin = 6;
    END
    ELSE IF @Trimestre = 3
    BEGIN
        SET @MesInicio = 7;
        SET @MesFin = 9;
    END
    ELSE IF @Trimestre = 4
    BEGIN
        SET @MesInicio = 10;
        SET @MesFin = 12;
    END

    -- Obtener el total facturado por turno (mañana/tarde) y por mes
    SELECT 
        MONTH(f.Fecha) AS "Mes",
        CASE 
            WHEN DATEPART(HOUR, f.Hora) >= 8 AND DATEPART(HOUR, f.Hora) < 15
            THEN 'Turno Mañana'
            WHEN DATEPART(HOUR, f.Hora) >= 15 AND DATEPART(HOUR, f.Hora) < 21
            THEN 'Turno Tarde'
            ELSE 'Fuera de Turno'
        END AS "Turno",
        SUM(l.Subtotal) AS "TotalFacturado"
    FROM 
        Ventas.Factura f
    JOIN 
        Ventas.LineaFactura l ON f.IDFactura = l.FacturaID
    WHERE 
        YEAR(f.Fecha) = @Anio
        AND MONTH(f.Fecha) BETWEEN @MesInicio AND @MesFin
    GROUP BY 
        MONTH(f.Fecha),
        CASE 
            WHEN DATEPART(HOUR, f.Hora) >= 8 AND DATEPART(HOUR, f.Hora) < 15
            THEN 'Turno Mañana'
            WHEN DATEPART(HOUR, f.Hora) >= 15 AND DATEPART(HOUR, f.Hora) < 21
            THEN 'Turno Tarde'
            ELSE 'Fuera de Turno'
        END
    ORDER BY 
        MONTH(f.Fecha), "Turno"
    FOR XML PATH('TurnoFactura'), ROOT('ReporteFacturacionTrimestral');
END;
GO

CREATE OR ALTER PROCEDURE Reporte.ReporteCantidadProductosPorRangoFechasXML
    @FechaInicio DATE,       -- Fecha de inicio del rango
    @FechaFin DATE           -- Fecha de fin del rango
AS
BEGIN
    SET NOCOUNT ON;

    -- Verificación de que la fecha de inicio es anterior a la fecha de fin
    IF @FechaInicio >= @FechaFin
    BEGIN
        RAISERROR('La fecha de inicio debe ser anterior a la fecha de fin.', 16, 1);
        RETURN;
    END

    -- Consulta para obtener la cantidad total de productos vendidos en el rango de fechas
    SELECT 
        p.NombreProducto,
        SUM(l.Cantidad) AS CantidadVendida
    FROM 
        Ventas.LineaFactura l
    JOIN 
        Supermercado.Producto p ON l.ProductoID = p.ProductoID
    JOIN 
        Ventas.Factura f ON l.FacturaID = f.IDFactura
    WHERE 
        f.Fecha BETWEEN @FechaInicio AND @FechaFin
    GROUP BY 
        p.NombreProducto
    ORDER BY 
        CantidadVendida DESC
    FOR XML PATH('ProductoVendido'), ROOT('ReporteCantidadProductos');
END;
GO


--REVISALA ---Mostrar los 5 productos más vendidos en un mes, por semana --
CREATE OR ALTER PROCEDURE Reporte.ReporteTop5ProductosPorSemanaXML
    @Mes INT,        -- Mes (1 = Enero, 2 = Febrero, ..., 12 = Diciembre)
    @Anio INT        -- Año
AS
BEGIN
    SET NOCOUNT ON;

    -- Validación de que el mes ingresado sea válido (entre 1 y 12)
    IF @Mes < 1 OR @Mes > 12
    BEGIN
        THROW 50002, 'El mes ingresado es inválido. Debe ser un valor entre 1 y 12.', 1;
    END

    -- Consulta para obtener los 5 productos más vendidos por semana en un mes específico
    ;WITH ProductosPorSemana AS (
        SELECT 
            p.NombreProducto,
            DATEPART(WEEK, f.Fecha) AS Semana,          -- Número de semana en el mes
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

    -- Selección de los 5 productos más vendidos por semana, ordenado por semana y cantidad vendida
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
    FOR XML PATH('ProductoSemana'), ROOT('ReporteTop5ProductosPorSemana');
END;
GO



--5 MENOS VENDIDOS DEL MES --
CREATE OR ALTER PROCEDURE Reporte.ReporteMenosVendidosPorMesXML
    @Mes INT,        
    @Anio INT        
AS
BEGIN
    SET NOCOUNT ON;

    -- Validación de que el mes ingresado sea válido (entre 1 y 12)
    IF @Mes < 1 OR @Mes > 12
    BEGIN
        THROW 50002, 'El mes ingresado es inválido. Debe ser un valor entre 1 y 12.', 1;
    END

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

    -- Selección de los 5 productos menos vendidos, ordenado por la cantidad vendida
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
    FOR XML PATH('ProductoMenosVendido'), ROOT('ReporteMenosVendidosPorMes');
END;
GO

EXEC Reporte.ReporteFacturadoPorDiaXML 2019,3;