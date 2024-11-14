IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'Com5600G12')
BEGIN
    CREATE DATABASE Com5600G12;
END
GO

USE Com5600G12;
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Supermercado')
BEGIN
    EXEC('CREATE SCHEMA Supermercado');
END
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Services')
BEGIN
    EXEC('CREATE SCHEMA Services');
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
			Ciudad varchar(50),
			Direccion varchar(200),
			Horario varchar(100),
            Telefono VARCHAR(30)
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
            Genero CHAR(1),                     -- Género del cliente (opcional)
        );
    END

    -- Crear la tabla Empleado solo si no existe
    IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Supermercado.Empleado') AND type IN (N'U'))
    BEGIN
        CREATE TABLE Supermercado.Empleado (
			EmpleadoID INT PRIMARY KEY IDENTITY(1,1),
            Legajo INT UNIQUE,
            Nombre VARCHAR(100) NOT NULL,
            Apellido VARCHAR(100) NOT NULL,
			Dni INT NOT NULL,
			Direccion varchar(100) NOT NULL,
            Email varchar(100),
			EmailEmpresa varchar(100),
			cargo varchar(50) NOT NULL,
            SucursalID INT NOT NULL,
			Turno varchar(30),
            FOREIGN KEY (SucursalID) REFERENCES Supermercado.Sucursal(SucursalID)
        );
    END

	IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Supermercado.EmpleadoEncriptado') AND type IN (N'U'))
	BEGIN
		CREATE TABLE Supermercado.EmpleadoEncriptado (
			Legajo INT PRIMARY KEY,
			Nombre VARBINARY(256) NOT NULL,            -- Encriptado
			Apellido VARBINARY(256) NOT NULL,          -- Encriptado
			Dni VARBINARY(256) NOT NULL,               -- Encriptado
			Direccion VARBINARY(256) NOT NULL,         -- Encriptado
			Email VARBINARY(256),                      -- Encriptado
			EmailEmpresa NVARCHAR(100),                -- No encriptado
			Cargo NVARCHAR(50) NOT NULL,               -- No encriptado
			SucursalID INT NOT NULL,
			Turno NVARCHAR(30),                        -- No encriptado
			FOREIGN KEY (SucursalID) REFERENCES Supermercado.Sucursal(SucursalID)
		);
	END;
	

    -- Crear la tabla Producto solo si no existe
    IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Supermercado.Producto') AND type IN (N'U'))
    BEGIN
        CREATE TABLE Supermercado.Producto (
            ProductoID INT PRIMARY KEY IDENTITY(1,1),
            Categoria VARCHAR(200) NOT NULL,
            NombreProducto VARCHAR(200) NOT NULL,
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
			IdMedioPago INT PRIMARY KEY IDENTITY(1,1),
			MedioPagoName VARCHAR(50),
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
			FacturaNC INT NULL, -- Si llega a ser nota de credito necesita estar asociada a una factura
			sucursal INT NOT NULL,
            Producto INT,
            Cantidad INT,
            Fecha DATE NOT NULL,
            Hora TIME NOT NULL,
            MedioPago INT NOT NULL,
            Empleado INT NOT NULL,
			Cliente INT NOT NULL,
            IdentificadorPago VARCHAR(50) NULL
			FOREIGN KEY (Empleado) REFERENCES Supermercado.Empleado(Legajo),
			FOREIGN KEY (FacturaNC) REFERENCES Ventas.Factura(IDFactura),
			FOREIGN KEY (Producto) REFERENCES Supermercado.Producto(ProductoID),
			FOREIGN KEY (MedioPago) REFERENCES Ventas.MediosPago(IdMedioPago),
			FOREIGN KEY (Cliente) REFERENCES Supermercado.Cliente(ClienteID),
			FOREIGN KEY (Sucursal) REFERENCES Supermercado.Sucursal(SucursalID)
        );
    END
END;
GO

-- CREAMOS TODAS LAS TABLAS SI NO ESTAN CREADAS--
EXEC Supermercado.crearTablas;
