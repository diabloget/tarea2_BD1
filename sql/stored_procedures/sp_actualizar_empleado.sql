USE mi_db;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_actualizar_empleado
  @Id                      INT,
  @ValorDocumentoIdentidad VARCHAR(20),
  @Nombre                  VARCHAR(128),
  @IdPuesto                INT,
  @IdPostByUser            INT,
  @PostInIP                VARCHAR(45),
  @Codigo                  INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @CedulaAntes VARCHAR(20), @NombreAntes VARCHAR(128), @PuestoAntes VARCHAR(128), @SaldoAntes DECIMAL(10,2);
  DECLARE @NombrePuestoNuevo VARCHAR(128);

  SELECT
    @CedulaAntes = e.ValorDocumentoIdentidad,
    @NombreAntes = e.Nombre,
    @PuestoAntes = p.Nombre,
    @SaldoAntes  = e.SaldoVacaciones
  FROM dbo.Empleado AS e
  JOIN dbo.Puesto   AS p ON p.Id = e.IdPuesto
  WHERE e.Id = @Id;

  SELECT @NombrePuestoNuevo = Nombre FROM dbo.Puesto WHERE Id = @IdPuesto;

  IF EXISTS (SELECT 1 FROM dbo.Empleado WHERE ValorDocumentoIdentidad = @ValorDocumentoIdentidad AND Id <> @Id AND EsActivo = 1)
  BEGIN
    SET @Codigo = 50006;
    INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP, PostTime)
    VALUES (7,
      'Error 50006 | Antes: ' + @CedulaAntes + ' / ' + @NombreAntes + ' / ' + @PuestoAntes +
      ' | Después: ' + @ValorDocumentoIdentidad + ' / ' + @Nombre + ' / ' + ISNULL(@NombrePuestoNuevo,'') +
      ' | Saldo: ' + CAST(@SaldoAntes AS VARCHAR),
      @IdPostByUser, @PostInIP, GETDATE());
    RETURN;
  END

  IF EXISTS (SELECT 1 FROM dbo.Empleado WHERE Nombre = @Nombre AND Id <> @Id AND EsActivo = 1)
  BEGIN
    SET @Codigo = 50007;
    INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP, PostTime)
    VALUES (7,
      'Error 50007 | Antes: ' + @CedulaAntes + ' / ' + @NombreAntes + ' / ' + @PuestoAntes +
      ' | Después: ' + @ValorDocumentoIdentidad + ' / ' + @Nombre + ' / ' + ISNULL(@NombrePuestoNuevo,'') +
      ' | Saldo: ' + CAST(@SaldoAntes AS VARCHAR),
      @IdPostByUser, @PostInIP, GETDATE());
    RETURN;
  END

  UPDATE dbo.Empleado
  SET ValorDocumentoIdentidad = @ValorDocumentoIdentidad,
      Nombre                  = @Nombre,
      IdPuesto                = @IdPuesto
  WHERE Id = @Id;

  SET @Codigo = 0;

  INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP, PostTime)
  VALUES (8,
    'Antes: ' + @CedulaAntes + ' / ' + @NombreAntes + ' / ' + @PuestoAntes +
    ' | Después: ' + @ValorDocumentoIdentidad + ' / ' + @Nombre + ' / ' + ISNULL(@NombrePuestoNuevo,'') +
    ' | Saldo: ' + CAST(@SaldoAntes AS VARCHAR),
    @IdPostByUser, @PostInIP, GETDATE());
END;
GO