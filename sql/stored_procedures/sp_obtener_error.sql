USE mi_db;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_obtener_error
  @Codigo INT
AS
BEGIN
  SET NOCOUNT ON;
  SELECT Descripcion FROM dbo.Error WHERE Codigo = @Codigo;
END;
GO