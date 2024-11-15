-- Trabajo Práctico Integrador
-- Grupo 12, Integrantes:
-- Didolich Martin Alejandro, 43664688
-- Martinez Fabricio Solomita, 43871283
-- Luis Alexander Romero, 40228032

-- Fecha de entrega: 15/11/2024
-- Materia: Bases de datos aplicada, Comision 5600

-- Script de generacion de esquemas y tablas
-- Ejecutar en el orden en que estan declaradas las sentencias

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

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Supervisor')
BEGIN
    EXEC('CREATE SCHEMA Supervisor');
END
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Reporte')
BEGIN
    EXEC('CREATE SCHEMA Reporte');
END
GO

CREATE OR ALTER PROCEDURE Supermercado.crearTablas
AS
BEGIN

    IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Supermercado.Sucursal') AND type IN (N'U'))
    BEGIN
        CREATE TABLE Supermercado.Sucursal (
            SucursalID INT PRIMARY KEY IDENTITY(1,1),
			Ciudad varchar(50),
			Direccion varchar(200),
			Horario varchar(100),
            Telefono VARCHAR(30),
			CiudadFake VARCHAR(50) NULL
        );
    END

    IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Supermercado.Cliente') AND type IN (N'U'))
    BEGIN
        CREATE TABLE Supermercado.Cliente (
            ClienteID INT PRIMARY KEY IDENTITY(1,1),
            Nombre VARCHAR(100) NOT NULL,
            Ciudad VARCHAR(100) NOT NULL,    
            TipoCliente VARCHAR(30) NOT NULL,  
            Genero CHAR(1),
        );
    END

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
			EmpleadoID INT PRIMARY KEY IDENTITY(1,1),
            Legajo INT UNIQUE,
			Nombre VARBINARY(256) NOT NULL,            
			Apellido VARBINARY(256) NOT NULL,          
			Dni VARBINARY(256) NOT NULL,               
			Direccion VARBINARY(256) NOT NULL,         
			Email VARBINARY(256),                      
			EmailEmpresa NVARCHAR(100),                
			Cargo NVARCHAR(50) NOT NULL,               
			SucursalID INT NOT NULL,
			Turno NVARCHAR(30),                        
			FOREIGN KEY (SucursalID) REFERENCES Supermercado.Sucursal(SucursalID)
		);
	END;
	
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
			deleted_at DATETIME NULL,
        );
    END

    IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Ventas.MediosPago') AND type IN (N'U'))
    BEGIN
		CREATE TABLE Ventas.MediosPago (
			IdMedioPago INT PRIMARY KEY IDENTITY(1,1),
			MedioPagoName VARCHAR(50),
			Descripcion VARCHAR(255)
		);
    END


    IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Ventas.Factura') AND type IN (N'U'))
    BEGIN
        CREATE TABLE Ventas.Factura (
			IDFactura INT PRIMARY KEY IDENTITY(1,1),
            nroFactura VARCHAR(50) UNIQUE,
            TipoFactura VARCHAR(10), --Aca puede ser factura o nota de credito
			FacturaNC INT NULL, -- Si llega a ser nota de credito necesita estar asociada a una factura
			sucursalID INT NOT NULL,
            Fecha DATE NOT NULL,
            Hora TIME NOT NULL,
            MedioPago INT NOT NULL,
            Empleado INT NOT NULL,
			Cliente INT NOT NULL,
            IdentificadorPago VARCHAR(50) NULL,
			FOREIGN KEY (Empleado) REFERENCES Supermercado.Empleado(EmpleadoID),
			FOREIGN KEY (FacturaNC) REFERENCES Ventas.Factura(IDFactura),
			FOREIGN KEY (MedioPago) REFERENCES Ventas.MediosPago(IdMedioPago),
			FOREIGN KEY (Cliente) REFERENCES Supermercado.Cliente(ClienteID),
			FOREIGN KEY (sucursalID) REFERENCES Supermercado.Sucursal(SucursalID)
        );
    END

	IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Ventas.LineaFactura') AND type IN (N'U'))
    BEGIN
        CREATE TABLE Ventas.LineaFactura (
			IDLineaFactura INT PRIMARY KEY IDENTITY(1,1),
			Cantidad INT NOT NULL,
			ProductoID INT NOT NULL,
			FacturaID INT NOT NULL,
			Subtotal DECIMAL(10,2) NOT NULL,
			FOREIGN KEY (ProductoID) REFERENCES Supermercado.Producto(ProductoID),
			FOREIGN KEY (FacturaID) REFERENCES Ventas.Factura(IDFactura)
        );
    END
END;
GO

EXEC Supermercado.crearTablas;