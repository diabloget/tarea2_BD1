IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'mi_db')
BEGIN
  CREATE DATABASE mi_db;
END
GO

USE mi_db;
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Puesto')
CREATE TABLE dbo.Puesto (
  Id           INT IDENTITY(1,1) PRIMARY KEY,
  Nombre       VARCHAR(128) NOT NULL UNIQUE,
  SalarioxHora MONEY        NOT NULL
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Usuario')
CREATE TABLE dbo.Usuario (
  Id       INT          PRIMARY KEY,
  Username VARCHAR(64)  NOT NULL UNIQUE,
  Password VARCHAR(128) NOT NULL
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Empleado')
CREATE TABLE dbo.Empleado (
  Id                      INT           IDENTITY(1,1) PRIMARY KEY,
  IdPuesto                INT           NOT NULL REFERENCES dbo.Puesto(Id),
  ValorDocumentoIdentidad VARCHAR(20)   NOT NULL UNIQUE,
  Nombre                  VARCHAR(128)  NOT NULL UNIQUE,
  FechaContratacion       DATE          NOT NULL,
  SaldoVacaciones         DECIMAL(10,2) NOT NULL DEFAULT 0,
  EsActivo                BIT           NOT NULL DEFAULT 1
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TipoMovimiento')
CREATE TABLE dbo.TipoMovimiento (
  Id         INT          PRIMARY KEY,
  Nombre     VARCHAR(128) NOT NULL UNIQUE,
  TipoAccion VARCHAR(10)  NOT NULL CHECK (TipoAccion IN ('Credito', 'Debito'))
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Movimiento')
CREATE TABLE dbo.Movimiento (
  Id               INT           IDENTITY(1,1) PRIMARY KEY,
  IdEmpleado       INT           NOT NULL REFERENCES dbo.Empleado(Id),
  IdTipoMovimiento INT           NOT NULL REFERENCES dbo.TipoMovimiento(Id),
  Fecha            DATE          NOT NULL,
  Monto            DECIMAL(10,2) NOT NULL,
  NuevoSaldo       DECIMAL(10,2) NOT NULL,
  IdPostByUser     INT           NOT NULL REFERENCES dbo.Usuario(Id),
  PostInIP         VARCHAR(45)   NOT NULL,
  PostTime         DATETIME      NOT NULL
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TipoEvento')
CREATE TABLE dbo.TipoEvento (
  Id     INT          PRIMARY KEY,
  Nombre VARCHAR(128) NOT NULL UNIQUE
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'BitacoraEvento')
CREATE TABLE dbo.BitacoraEvento (
  Id           INT          IDENTITY(1,1) PRIMARY KEY,
  IdTipoEvento INT          NOT NULL REFERENCES dbo.TipoEvento(Id),
  Descripcion  VARCHAR(MAX) NULL,
  IdPostByUser INT          NOT NULL REFERENCES dbo.Usuario(Id),
  PostInIP     VARCHAR(45)  NOT NULL,
  PostTime     DATETIME     NOT NULL
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Error')
CREATE TABLE dbo.Error (
  Codigo      INT          PRIMARY KEY,
  Descripcion VARCHAR(256) NOT NULL
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DBError')
CREATE TABLE dbo.DBError (
  Id          INT          IDENTITY(1,1) PRIMARY KEY,
  UserName    VARCHAR(64)  NULL,
  Number      INT          NULL,
  State       INT          NULL,
  Severity    INT          NULL,
  Line        INT          NULL,
  [Procedure] VARCHAR(128) NULL,
  Message     VARCHAR(MAX) NULL,
  DateTime    DATETIME     NOT NULL DEFAULT GETDATE()
);
GO