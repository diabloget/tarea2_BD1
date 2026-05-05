USE mi_db;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_actualizar_empleado
  @inId                      INT
, @inValorDocumentoIdentidad VARCHAR(20)
, @inNombre                  VARCHAR(128)
, @inIdPuesto                INT
, @inIdPostByUser            INT
, @inPostInIP                VARCHAR(45)
, @outResultCode             INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  -- lecturas y validaciones
  DECLARE @vCedulaAntes      VARCHAR(20);
  DECLARE @vNombreAntes      VARCHAR(128);
  DECLARE @vPuestoAntes      VARCHAR(128);
  DECLARE @vSaldoAntes       DECIMAL(10,2);
  DECLARE @vNombrePuestoNuevo VARCHAR(128);

  SELECT @vCedulaAntes = E.ValorDocumentoIdentidad
       , @vNombreAntes = E.Nombre
       , @vPuestoAntes = P.Nombre
       , @vSaldoAntes  = E.SaldoVacaciones
  FROM   dbo.Empleado E
  JOIN   dbo.Puesto   P ON (P.Id = E.IdPuesto)
  WHERE  (E.Id = @inId);

  SELECT @vNombrePuestoNuevo = P.Nombre
  FROM   dbo.Puesto P
  WHERE  (P.Id = @inIdPuesto);

  IF EXISTS (SELECT 1 FROM dbo.Empleado E WHERE (E.ValorDocumentoIdentidad = @inValorDocumentoIdentidad) AND (E.Id <> @inId) AND (E.EsActivo = 1))
  BEGIN
    SET @outResultCode = 50006;
    INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP, PostTime)
    VALUES (7,
      'Error 50006 | Antes: ' + @vCedulaAntes + ' / ' + @vNombreAntes + ' / ' + @vPuestoAntes +
      ' | Después: ' + @inValorDocumentoIdentidad + ' / ' + @inNombre + ' / ' + ISNULL(@vNombrePuestoNuevo,'') +
      ' | Saldo: ' + CAST(@vSaldoAntes AS VARCHAR),
      @inIdPostByUser, @inPostInIP, GETDATE());
    RETURN;
  END

  IF EXISTS (SELECT 1 FROM dbo.Empleado E WHERE (E.Nombre = @inNombre) AND (E.Id <> @inId) AND (E.EsActivo = 1))
  BEGIN
    SET @outResultCode = 50007;
    INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP, PostTime)
    VALUES (7,
      'Error 50007 | Antes: ' + @vCedulaAntes + ' / ' + @vNombreAntes + ' / ' + @vPuestoAntes +
      ' | Después: ' + @inValorDocumentoIdentidad + ' / ' + @inNombre + ' / ' + ISNULL(@vNombrePuestoNuevo,'') +
      ' | Saldo: ' + CAST(@vSaldoAntes AS VARCHAR),
      @inIdPostByUser, @inPostInIP, GETDATE());
    RETURN;
  END

  SET @outResultCode = 0;

  -- transacción
  BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE dbo.Empleado
    SET    ValorDocumentoIdentidad = @inValorDocumentoIdentidad
         , Nombre                  = @inNombre
         , IdPuesto                = @inIdPuesto
    WHERE  (Id = @inId);

    INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP, PostTime)
    VALUES (8,
      'Antes: ' + @vCedulaAntes + ' / ' + @vNombreAntes + ' / ' + @vPuestoAntes +
      ' | Después: ' + @inValorDocumentoIdentidad + ' / ' + @inNombre + ' / ' + ISNULL(@vNombrePuestoNuevo,'') +
      ' | Saldo: ' + CAST(@vSaldoAntes AS VARCHAR),
      @inIdPostByUser, @inPostInIP, GETDATE());

    COMMIT TRANSACTION;
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @outResultCode = ERROR_NUMBER() + 50000;
    INSERT INTO dbo.DBError (UserName, Number, State, Severity, Line, [Procedure], Message, DateTime)
    VALUES (SUSER_SNAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(),
            ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE(), GETDATE());
    THROW;
  END CATCH
END;
GO