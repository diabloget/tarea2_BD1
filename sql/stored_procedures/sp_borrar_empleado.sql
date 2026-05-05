USE mi_db;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_borrar_empleado
  @inId          INT
, @inIdPostByUser INT
, @inPostInIP    VARCHAR(45)
, @outResultCode INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  -- lecturas
  DECLARE @vCedula VARCHAR(20);
  DECLARE @vNombre VARCHAR(128);
  DECLARE @vPuesto VARCHAR(128);
  DECLARE @vSaldo  DECIMAL(10,2);

  SELECT @vCedula = E.ValorDocumentoIdentidad
       , @vNombre = E.Nombre
       , @vPuesto = P.Nombre
       , @vSaldo  = E.SaldoVacaciones
  FROM   dbo.Empleado E
  JOIN   dbo.Puesto   P ON (P.Id = E.IdPuesto)
  WHERE  (E.Id = @inId);

  SET @outResultCode = 0;

  -- transacción
  BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE dbo.Empleado
    SET    EsActivo = 0
    WHERE  (Id = @inId);

    INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP, PostTime)
    VALUES (10,
      'Cédula: ' + ISNULL(@vCedula,'') + ' | Nombre: ' + ISNULL(@vNombre,'') +
      ' | Puesto: ' + ISNULL(@vPuesto,'') + ' | Saldo: ' + CAST(ISNULL(@vSaldo,0) AS VARCHAR),
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