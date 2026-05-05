USE mi_db;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_listar_movimientos
  @inIdEmpleado  INT
, @outResultCode INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  BEGIN TRY
    SELECT M.Id
         , M.Fecha
         , TM.Nombre     AS TipoMovimiento
         , TM.TipoAccion
         , M.Monto
         , M.NuevoSaldo
         , U.Username    AS Usuario
         , M.PostInIP
         , M.PostTime
    FROM   dbo.Movimiento     M
    JOIN   dbo.TipoMovimiento TM ON (TM.Id = M.IdTipoMovimiento)
    JOIN   dbo.Usuario        U  ON (U.Id  = M.IdPostByUser)
    WHERE  (M.IdEmpleado = @inIdEmpleado)
    ORDER BY M.Fecha DESC, M.PostTime DESC;

    SET @outResultCode = 0;
  END TRY
  BEGIN CATCH
    SET @outResultCode = ERROR_NUMBER() + 50000;
    INSERT INTO dbo.DBError (UserName, Number, State, Severity, Line, [Procedure], Message, DateTime)
    VALUES (SUSER_SNAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(),
            ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE(), GETDATE());
    THROW;
  END CATCH
END;
GO