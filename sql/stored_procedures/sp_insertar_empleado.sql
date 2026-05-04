USE mi_db;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_insertar_empleado
  @ValorDocumentoIdentidad VARCHAR(20),
  @Nombre                  VARCHAR(128),
  @IdPuesto                INT,
  @FechaContratacion       DATE,
  @IdPostByUser            INT,
  @PostInIP                VARCHAR(45),
  @Codigo                  INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @NombrePuesto VARCHAR(128);
  SELECT @NombrePuesto = Nombre FROM dbo.Puesto WHERE Id = @IdPuesto;

  IF EXISTS (SELECT 1 FROM dbo.Empleado WHERE ValorDocumentoIdentidad = @ValorDocumentoIdentidad AND EsActivo = 1)
  BEGIN
    SET @Codigo = 50004;
    INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP, PostTime)
    VALUES (5, 'Error 50004 | Cédula: ' + @ValorDocumentoIdentidad + ' | Nombre: ' + @Nombre + ' | Puesto: ' + ISNULL(@NombrePuesto, ''), @IdPostByUser, @PostInIP, GETDATE());
    RETURN;
  END

  IF EXISTS (SELECT 1 FROM dbo.Empleado WHERE Nombre = @Nombre AND EsActivo = 1)
  BEGIN
    SET @Codigo = 50005;
    INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP, PostTime)
    VALUES (5, 'Error 50005 | Cédula: ' + @ValorDocumentoIdentidad + ' | Nombre: ' + @Nombre + ' | Puesto: ' + ISNULL(@NombrePuesto, ''), @IdPostByUser, @PostInIP, GETDATE());
    RETURN;
  END

  INSERT INTO dbo.Empleado (IdPuesto, ValorDocumentoIdentidad, Nombre, FechaContratacion, SaldoVacaciones, EsActivo)
  VALUES (@IdPuesto, @ValorDocumentoIdentidad, @Nombre, @FechaContratacion, 0, 1);

  SET @Codigo = 0;

  INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP, PostTime)
  VALUES (6, 'Cédula: ' + @ValorDocumentoIdentidad + ' | Nombre: ' + @Nombre + ' | Puesto: ' + ISNULL(@NombrePuesto, ''), @IdPostByUser, @PostInIP, GETDATE());
END;
GO