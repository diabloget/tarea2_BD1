USE mi_db;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_insertar_empleado
  @inValorDocumentoIdentidad VARCHAR(20)
, @inNombre                  VARCHAR(128)
, @inIdPuesto                INT
, @inFechaContratacion       DATE
, @inIdPostByUser            INT
, @inPostInIP                VARCHAR(45)
, @outResultCode             INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  -- validaciones y lecturas
  DECLARE @vNombrePuesto VARCHAR(128);

  SELECT @vNombrePuesto = P.Nombre
  FROM   dbo.Puesto P
  WHERE  (P.Id = @inIdPuesto);

  IF EXISTS (SELECT 1 FROM dbo.Empleado E WHERE (E.ValorDocumentoIdentidad = @inValorDocumentoIdentidad) AND (E.EsActivo = 1))
  BEGIN
    SET @outResultCode = 50004;
    INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP, PostTime)
    VALUES (5, 'Error 50004 | Cédula: ' + @inValorDocumentoIdentidad + ' | Nombre: ' + @inNombre + ' | Puesto: ' + ISNULL(@vNombrePuesto, ''), @inIdPostByUser, @inPostInIP, GETDATE());
    RETURN;
  END

  IF EXISTS (SELECT 1 FROM dbo.Empleado E WHERE (E.Nombre = @inNombre) AND (E.EsActivo = 1))
  BEGIN
    SET @outResultCode = 50005;
    INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP, PostTime)
    VALUES (5, 'Error 50005 | Cédula: ' + @inValorDocumentoIdentidad + ' | Nombre: ' + @inNombre + ' | Puesto: ' + ISNULL(@vNombrePuesto, ''), @inIdPostByUser, @inPostInIP, GETDATE());
    RETURN;
  END

  SET @outResultCode = 0;

  -- transacción
  BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO dbo.Empleado (IdPuesto, ValorDocumentoIdentidad, Nombre, FechaContratacion, SaldoVacaciones, EsActivo)
    VALUES (@inIdPuesto, @inValorDocumentoIdentidad, @inNombre, @inFechaContratacion, 0, 1);

    INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP, PostTime)
    VALUES (6, 'Cédula: ' + @inValorDocumentoIdentidad + ' | Nombre: ' + @inNombre + ' | Puesto: ' + ISNULL(@vNombrePuesto, ''), @inIdPostByUser, @inPostInIP, GETDATE());

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