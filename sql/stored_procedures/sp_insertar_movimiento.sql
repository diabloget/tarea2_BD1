USE mi_db;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_insertar_movimiento
  @inIdEmpleado       INT
, @inIdTipoMovimiento INT
, @inMonto            DECIMAL(10,2)
, @inIdPostByUser     INT
, @inPostInIP         VARCHAR(45)
, @outResultCode      INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  -- validaciones y cálculos
  DECLARE @vSaldoActual DECIMAL(10,2);
  DECLARE @vTipoAccion  VARCHAR(10);
  DECLARE @vNuevoSaldo  DECIMAL(10,2);
  DECLARE @vNombreTipo  VARCHAR(128);
  DECLARE @vCedulaEmp   VARCHAR(20);
  DECLARE @vNombreEmp   VARCHAR(128);

  SELECT @vSaldoActual = E.SaldoVacaciones
       , @vCedulaEmp   = E.ValorDocumentoIdentidad
       , @vNombreEmp   = E.Nombre
  FROM   dbo.Empleado E
  WHERE  (E.Id = @inIdEmpleado);

  SELECT @vTipoAccion = TM.TipoAccion
       , @vNombreTipo = TM.Nombre
  FROM   dbo.TipoMovimiento TM
  WHERE  (TM.Id = @inIdTipoMovimiento);

  SET @vNuevoSaldo = CASE
    WHEN @vTipoAccion = 'Credito' THEN @vSaldoActual + @inMonto
    ELSE @vSaldoActual - @inMonto
  END;

  IF (@vNuevoSaldo < 0)
  BEGIN
    SET @outResultCode = 50011;
    INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP, PostTime)
    VALUES (13,
      'Error 50011 | Cédula: ' + @vCedulaEmp + ' | Nombre: ' + @vNombreEmp +
      ' | Saldo actual: ' + CAST(@vSaldoActual AS VARCHAR) +
      ' | Tipo: ' + @vNombreTipo + ' | Monto: ' + CAST(@inMonto AS VARCHAR),
      @inIdPostByUser, @inPostInIP, GETDATE());
    RETURN;
  END

  SET @outResultCode = 0;

  -- transacción
  BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO dbo.Movimiento (IdEmpleado, IdTipoMovimiento, Fecha, Monto, NuevoSaldo, IdPostByUser, PostInIP, PostTime)
    VALUES (@inIdEmpleado, @inIdTipoMovimiento, CAST(GETDATE() AS DATE), @inMonto, @vNuevoSaldo, @inIdPostByUser, @inPostInIP, GETDATE());

    UPDATE dbo.Empleado
    SET    SaldoVacaciones = @vNuevoSaldo
    WHERE  (Id = @inIdEmpleado);

    INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP, PostTime)
    VALUES (14,
      'Cédula: ' + @vCedulaEmp + ' | Nombre: ' + @vNombreEmp +
      ' | Nuevo saldo: ' + CAST(@vNuevoSaldo AS VARCHAR) +
      ' | Tipo: ' + @vNombreTipo + ' | Monto: ' + CAST(@inMonto AS VARCHAR),
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