USE mi_db;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_listar_tipos_movimiento
AS
BEGIN
  SET NOCOUNT ON;
  SELECT Id, Nombre, TipoAccion FROM dbo.TipoMovimiento ORDER BY Nombre ASC;
END;
GO