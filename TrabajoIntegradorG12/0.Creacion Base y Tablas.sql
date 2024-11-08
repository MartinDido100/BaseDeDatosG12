IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'COMERCIO')
BEGIN
    CREATE DATABASE COMERCIO;
END
GO

USE COMERCIO;
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Supermercado')
BEGIN
    EXEC('CREATE SCHEMA Supermercado');
END
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Ventas')
BEGIN
    EXEC('CREATE SCHEMA Ventas');
END
GO

CREATE OR ALTER PROCEDURE Supermercado.crearTablas
AS
BEGIN
    -- Crear la tabla Sucursal solo si no existe
    IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Supermercado.Sucursal') AND type IN (N'U'))
    BEGIN
        CREATE TABLE Supermercado.Sucursal (
            SucursalID INT PRIMARY KEY IDENTITY(1,1),
            Nombre VARCHAR(30) NOT NULL
        );
    END

    -- Crear la tabla Cliente solo si no existe
    IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Supermercado.Cliente') AND type IN (N'U'))
    BEGIN
        CREATE TABLE Supermercado.Cliente (
            ClienteID INT PRIMARY KEY IDENTITY(1,1),
            Nombre VARCHAR(100) NOT NULL,
            Ciudad VARCHAR(100) NOT NULL,       -- Ciudad donde reside el cliente
            TipoCliente VARCHAR(30) NOT NULL,   -- Tipo de cliente (minorista, mayorista, etc.)
            Genero CHAR(1),                     -- G�nero del cliente (opcional)
            SucursalID INT NOT NULL,             -- Un cliente en una sola sucursal
            FOREIGN KEY (SucursalID) REFERENCES Supermercado.Sucursal(SucursalID)
        );
    END

    -- Crear la tabla Empleado solo si no existe
    IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Supermercado.Empleado') AND type IN (N'U'))
    BEGIN
        CREATE TABLE Supermercado.Empleado (
            Legajo INT PRIMARY KEY IDENTITY(1,1),
            Nombre VARCHAR(100) NOT NULL,
            Apellido VARCHAR(100) NOT NULL,
            FechaIngreso DATE NOT NULL,
            SucursalID INT NOT NULL,
            FOREIGN KEY (SucursalID) REFERENCES Supermercado.Sucursal(SucursalID)
        );
    END

    -- Crear la tabla Producto solo si no existe
    IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Supermercado.Producto') AND type IN (N'U'))
    BEGIN
        CREATE TABLE Supermercado.Producto (
            ProductoID INT PRIMARY KEY IDENTITY(1,1),
            Categoria VARCHAR(200) NOT NULL,
            NombreProducto NVARCHAR(200) NOT NULL,
            PrecioUnitario DECIMAL(10, 2) NOT NULL,
			PrecioUnitarioUsd DECIMAL(10,2) NULL,
            PrecioReferencia DECIMAL(10, 2) NULL,
            UnidadReferencia VARCHAR(100) NULL,
            Fecha DATETIME NOT NULL,
			Proveedor VARCHAR(100) NULL,
        );
    END

    -- Crear la tabla MediosPago solo si no existe
    IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Ventas.MediosPago') AND type IN (N'U'))
    BEGIN
		CREATE TABLE Ventas.MediosPago (
			MedioPagoName VARCHAR(50) PRIMARY KEY,
			Descripcion VARCHAR(255)
		);
    END

	-- Crear la tabla Factura solo si no existe
	-- ACLARACION: Creamos la tabla factura que representa un solo producto (Por como venia el archivo de ventas decidimos hacerlo asi)
	-- entendemos que es mejor crear una factura y muchas lineas de factura para que la misma pueda tener varios productos
    IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Ventas.Factura') AND type IN (N'U'))
    BEGIN
        CREATE TABLE Ventas.Factura (
			IDFactura INT PRIMARY KEY IDENTITY(1,1),
            nroFactura VARCHAR(50) UNIQUE,
            TipoFactura VARCHAR(10), --Aca puede ser factura o nota de credito
			IDFacturaNC INT NULL, -- Si llega a ser nota de credito necesita estar asociada a una factura
            Ciudad VARCHAR(50),
            TipoCliente VARCHAR(20),
            Genero VARCHAR(10),
            Producto INT,
            PrecioUnitario DECIMAL(10,2),
            Cantidad INT,
            Fecha DATE NOT NULL,
            Hora TIME NOT NULL,
            MedioPago VARCHAR(50) NOT NULL,
            Empleado INT,
            IdentificadorPago VARCHAR(50) NULL
			FOREIGN KEY (Empleado) REFERENCES Supermercado.Empleado(Legajo),
			FOREIGN KEY (IDFacturaNC) REFERENCES Ventas.Factura(IDFactura),
			FOREIGN KEY (Producto) REFERENCES Supermercado.Producto(ProductoID),
			FOREIGN KEY (MedioPago) REFERENCES Ventas.MediosPago(MedioPagoName)
        );
    END
END;
GO

-- CREAMOS TODAS LAS TABLAS SI NO ESTAN CREADAS--
EXEC Supermercado.crearTablas;
