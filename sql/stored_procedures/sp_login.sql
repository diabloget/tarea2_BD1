USE mi_db;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_login
  @Username VARCHAR(64),
  @Password VARCHAR(128),
  @IP       VARCHAR(45),
  @Codigo   INT OUTPUT  -- exito si 0
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @IdUsuario    INT;
  DECLARE @IdTipoEvento INT;
  DECLARE @Intentos     INT;
  DECLARE @Descripcion  VARCHAR(MAX);

  -- Verificar si el usuario existe
  SELECT @IdUsuario = Id
  FROM dbo.Usuario
  WHERE Username = @Username;

  IF @IdUsuario IS NULL
  BEGIN
    SET @Codigo = 50001; -- Username no existe

    -- Registrar intento fallido
    INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP, PostTime)
    VALUES (2, 'Username no existe: ' + @Username, 1, @IP, GETDATE());

    RETURN;
  END

  -- Verificar si está deshabilitado 
  SELECT @Intentos = COUNT(*)
  FROM dbo.BitacoraEvento
  WHERE IdPostByUser = @IdUsuario
    AND IdTipoEvento = 2
    AND PostTime >= DATEADD(MINUTE, -20, GETDATE());

  IF @Intentos >= 5
  BEGIN
    SET @Codigo = 50003; -- Login deshabilitado

    INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP, PostTime)
    VALUES (3, NULL, @IdUsuario, @IP, GETDATE());

    RETURN;
  END

  -- Verificar contraseña
  IF NOT EXISTS (SELECT 1 FROM dbo.Usuario WHERE Id = @IdUsuario AND Password = @Password)
  BEGIN
    SET @Codigo = 50002; -- Password incorrecta

    SET @Intentos = @Intentos + 1;
    SET @Descripcion = 'Intento ' + CAST(@Intentos AS VARCHAR) + ' en los últimos 20 minutos. Código: 50002';

    INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP, PostTime)
    VALUES (2, @Descripcion, @IdUsuario, @IP, GETDATE());

    RETURN;
  END

  -- Login exitoso
  SET @Codigo = 0;

  INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP, PostTime)
  VALUES (1, 'Exitoso', @IdUsuario, @IP, GETDATE());

  -- Devolver datos de usuario
  SELECT Id, Username FROM dbo.Usuario WHERE Id = @IdUsuario;
END;
GO