CREATE DATABASE mi_db;
GO

USE mi_db;
GO


-- Puesto
-- ID autoincremental (único catálogo sin ID fijo en el XML).
CREATE TABLE dbo.Puesto (
  Id           INT IDENTITY(1,1) PRIMARY KEY,
  Nombre       VARCHAR(128) NOT NULL UNIQUE,
  SalarioxHora MONEY        NOT NULL
);
GO


-- Usuario
-- ID fijo (viene del XML). Password en texto plano por ahora.
CREATE TABLE dbo.Usuario (
  Id       INT          PRIMARY KEY,
  Username VARCHAR(64)  NOT NULL UNIQUE,
  Password VARCHAR(128) NOT NULL
);
GO


-- Empleado
-- SaldoVacaciones inicia en 0 y se actualiza con movimientos.
-- EsActivo = 1 activo, 0 borrado lógico.
-- ValorDocumentoIdentidad y Nombre son únicos.
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


-- TipoMovimiento
-- ID fijo. TipoAccion determina si suma o resta al saldo.
CREATE TABLE dbo.TipoMovimiento (
  Id         INT          PRIMARY KEY,
  Nombre     VARCHAR(128) NOT NULL UNIQUE,
  TipoAccion VARCHAR(10)  NOT NULL CHECK (TipoAccion IN ('Credito', 'Debito'))
);
GO


-- Movimiento
-- NuevoSaldo se calcula en el SP de inserción.
-- PostInIP soporta IPv4 e IPv6 (máx 45 chars).
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


-- TipoEvento
-- ID fijo. Catálogo de tipos de entrada en la bitácora.

CREATE TABLE dbo.TipoEvento (
  Id     INT          PRIMARY KEY,
  Nombre VARCHAR(128) NOT NULL UNIQUE
);
GO


-- BitacoraEvento
-- Toda operación del sistema queda registrada aquí.
CREATE TABLE dbo.BitacoraEvento (
  Id           INT          IDENTITY(1,1) PRIMARY KEY,
  IdTipoEvento INT          NOT NULL REFERENCES dbo.TipoEvento(Id),
  Descripcion  VARCHAR(MAX) NULL,
  IdPostByUser INT          NOT NULL REFERENCES dbo.Usuario(Id),
  PostInIP     VARCHAR(45)  NOT NULL,
  PostTime     DATETIME     NOT NULL
);
GO


-- Error
-- Catálogo de errores de negocio. Codigo es el PK natural
-- (50001..50011) que los SPs devuelven a capa lógica.
CREATE TABLE dbo.Error (
  Codigo      INT          PRIMARY KEY,
  Descripcion VARCHAR(256) NOT NULL
);
GO

-- DBError
-- Registro de errores técnicos capturados en bloques CATCH.
CREATE TABLE dbo.DBError (
  Id        INT          IDENTITY(1,1) PRIMARY KEY,
  UserName  VARCHAR(64)  NULL,
  Number    INT          NULL,
  State     INT          NULL,
  Severity  INT          NULL,
  Line      INT          NULL,
  Procedure VARCHAR(128) NULL,
  Message   VARCHAR(MAX) NULL,
  DateTime  DATETIME     NOT NULL DEFAULT GETDATE()
);
GO