USE mi_db;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_listar_movimientos
  @IdEmpleado INT
AS
BEGIN
  SET NOCOUNT ON;
  SELECT
    m.Id,
    m.Fecha,
    tm.Nombre      AS TipoMovimiento,
    tm.TipoAccion,
    m.Monto,
    m.NuevoSaldo,
    u.Username     AS Usuario,
    m.PostInIP,
    m.PostTime
  FROM dbo.Movimiento      AS m
  JOIN dbo.TipoMovimiento  AS tm ON tm.Id = m.IdTipoMovimiento
  JOIN dbo.Usuario         AS u  ON u.Id  = m.IdPostByUser
  WHERE m.IdEmpleado = @IdEmpleado
  ORDER BY m.Fecha DESC, m.PostTime DESC;
END;
GO