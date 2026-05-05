USE mi_db;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_insertar_movimiento
  @IdEmpleado      INT,
  @IdTipoMovimiento INT,
  @Monto           DECIMAL(10,2),
  @IdPostByUser    INT,
  @PostInIP        VARCHAR(45),
  @Codigo          INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @SaldoActual   DECIMAL(10,2);
  DECLARE @TipoAccion    VARCHAR(10);
  DECLARE @NuevoSaldo    DECIMAL(10,2);
  DECLARE @NombreTipo    VARCHAR(128);
  DECLARE @CedulaEmp     VARCHAR(20);
  DECLARE @NombreEmp     VARCHAR(128);

  SELECT @SaldoActual = SaldoVacaciones,
         @CedulaEmp   = ValorDocumentoIdentidad,
         @NombreEmp   = Nombre
  FROM dbo.Empleado WHERE Id = @IdEmpleado;

  SELECT @TipoAccion = TipoAccion, @NombreTipo = Nombre
  FROM dbo.TipoMovimiento WHERE Id = @IdTipoMovimiento;

  SET @NuevoSaldo = CASE
    WHEN @TipoAccion = 'Credito' THEN @SaldoActual + @Monto
    ELSE @SaldoActual - @Monto
  END;

  IF @NuevoSaldo < 0
  BEGIN
    SET @Codigo = 50011;
    INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP, PostTime)
    VALUES (13,
      'Error 50011 | Cédula: ' + @CedulaEmp + ' | Nombre: ' + @NombreEmp +
      ' | Saldo actual: ' + CAST(@SaldoActual AS VARCHAR) +
      ' | Tipo: ' + @NombreTipo + ' | Monto: ' + CAST(@Monto AS VARCHAR),
      @IdPostByUser, @PostInIP, GETDATE());
    RETURN;
  END

  INSERT INTO dbo.Movimiento (IdEmpleado, IdTipoMovimiento, Fecha, Monto, NuevoSaldo, IdPostByUser, PostInIP, PostTime)
  VALUES (@IdEmpleado, @IdTipoMovimiento, CAST(GETDATE() AS DATE), @Monto, @NuevoSaldo, @IdPostByUser, @PostInIP, GETDATE());

  UPDATE dbo.Empleado SET SaldoVacaciones = @NuevoSaldo WHERE Id = @IdEmpleado;

  SET @Codigo = 0;

  INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP, PostTime)
  VALUES (14,
    'Cédula: ' + @CedulaEmp + ' | Nombre: ' + @NombreEmp +
    ' | Nuevo saldo: ' + CAST(@NuevoSaldo AS VARCHAR) +
    ' | Tipo: ' + @NombreTipo + ' | Monto: ' + CAST(@Monto AS VARCHAR),
    @IdPostByUser, @PostInIP, GETDATE());
END;
GO