USE mi_db;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_logout
  @IdUsuario INT,
  @IP        VARCHAR(45)
AS
BEGIN
  SET NOCOUNT ON;

  INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP, PostTime)
  VALUES (4, NULL, @IdUsuario, @IP, GETDATE());
END;
GO