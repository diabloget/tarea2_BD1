USE mi_db;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_carga_xml
  @xml           XML
, @outResultCode INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  SET @outResultCode = 0;

  BEGIN TRY
    BEGIN TRANSACTION;

    -- Puestos
    INSERT INTO dbo.Puesto (Nombre, SalarioxHora)
    SELECT X.value('@Nombre',       'VARCHAR(128)')
         , X.value('@SalarioxHora', 'MONEY')
    FROM   @xml.nodes('/Datos/Puestos/Puesto') AS T(X);

    -- TiposMovimiento
    INSERT INTO dbo.TipoMovimiento (Id, Nombre, TipoAccion)
    SELECT X.value('@Id',         'INT')
         , X.value('@Nombre',     'VARCHAR(128)')
         , X.value('@TipoAccion', 'VARCHAR(10)')
    FROM   @xml.nodes('/Datos/TiposMovimientos/TipoMovimiento') AS T(X);

    -- TiposEvento
    INSERT INTO dbo.TipoEvento (Id, Nombre)
    SELECT X.value('@Id',     'INT')
         , X.value('@Nombre', 'VARCHAR(128)')
    FROM   @xml.nodes('/Datos/TiposEvento/TipoEvento') AS T(X);

    -- Usuarios
    INSERT INTO dbo.Usuario (Id, Username, Password)
    SELECT X.value('@Id',     'INT')
         , X.value('@Nombre', 'VARCHAR(64)')
         , X.value('@Pass',   'VARCHAR(128)')
    FROM   @xml.nodes('/Datos/Usuarios/usuario') AS T(X);

    -- Errores
    INSERT INTO dbo.Error (Codigo, Descripcion)
    SELECT X.value('@Codigo',      'INT')
         , X.value('@Descripcion', 'VARCHAR(256)')
    FROM   @xml.nodes('/Datos/Error/error') AS T(X);

    -- Empleados 
    INSERT INTO dbo.Empleado (IdPuesto, ValorDocumentoIdentidad, Nombre, FechaContratacion, SaldoVacaciones, EsActivo)
    SELECT (SELECT P.Id FROM dbo.Puesto P WHERE (P.Nombre = X.value('@Puesto', 'VARCHAR(128)')))
         , X.value('@ValorDocumentoIdentidad', 'VARCHAR(20)')
         , X.value('@Nombre',                  'VARCHAR(128)')
         , X.value('@FechaContratacion',        'DATE')
         , 0
         , 1
    FROM   @xml.nodes('/Datos/Empleados/empleado') AS T(X);

    -- Movimientos procesados fecha por fecha en orden cronológico. (Lo pidió el profesor durante una clase)
    DECLARE @vFechas TABLE (Fecha DATE);
    DECLARE @vFechaActual DATE;

    INSERT INTO @vFechas (Fecha)
    SELECT DISTINCT X.value('@Fecha', 'DATE')
    FROM   @xml.nodes('/Datos/Movimientos/movimiento') AS T(X)
    ORDER BY 1 ASC;

    WHILE EXISTS (SELECT 1 FROM @vFechas)
    BEGIN
      SELECT TOP 1 @vFechaActual = F.Fecha
      FROM   @vFechas F
      ORDER BY F.Fecha ASC;

      -- Insertar movimientos de esta fecha con NuevoSaldo acumulado
      ;WITH MovimientosDia AS (
        SELECT (SELECT E.Id FROM dbo.Empleado E WHERE (E.ValorDocumentoIdentidad = X.value('@ValorDocId', 'VARCHAR(20)'))) AS IdEmpleado
             , (SELECT TM.Id FROM dbo.TipoMovimiento TM WHERE (TM.Nombre = X.value('@IdTipoMovimiento', 'VARCHAR(128)')))  AS IdTipoMovimiento
             , (SELECT TM.TipoAccion FROM dbo.TipoMovimiento TM WHERE (TM.Nombre = X.value('@IdTipoMovimiento', 'VARCHAR(128)'))) AS TipoAccion
             , X.value('@Fecha',    'DATE')          AS Fecha
             , X.value('@Monto',    'DECIMAL(10,2)') AS Monto
             , (SELECT U.Id FROM dbo.Usuario U WHERE (U.Username = X.value('@PostByUser', 'VARCHAR(64)'))) AS IdPostByUser
             , X.value('@PostInIP', 'VARCHAR(45)')   AS PostInIP
             , X.value('@PostTime', 'DATETIME')      AS PostTime
        FROM   @xml.nodes('/Datos/Movimientos/movimiento') AS T(X)
        WHERE  X.value('@Fecha', 'DATE') = @vFechaActual
      )
      , ConSaldo AS (
        SELECT MD.IdEmpleado
             , MD.IdTipoMovimiento
             , MD.Fecha
             , MD.Monto
             , E.SaldoVacaciones + SUM(CASE WHEN MD.TipoAccion = 'Credito' THEN MD.Monto ELSE -MD.Monto END)
                 OVER (PARTITION BY MD.IdEmpleado ORDER BY MD.PostTime ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS NuevoSaldo
             , MD.IdPostByUser
             , MD.PostInIP
             , MD.PostTime
        FROM   MovimientosDia MD
        JOIN   dbo.Empleado   E ON (E.Id = MD.IdEmpleado)
      )
      INSERT INTO dbo.Movimiento (IdEmpleado, IdTipoMovimiento, Fecha, Monto, NuevoSaldo, IdPostByUser, PostInIP, PostTime)
      SELECT CS.IdEmpleado, CS.IdTipoMovimiento, CS.Fecha, CS.Monto, CS.NuevoSaldo, CS.IdPostByUser, CS.PostInIP, CS.PostTime
      FROM   ConSaldo CS;

      -- Actualizar saldo de cada empleado afectado en fecha especifica
      UPDATE E
      SET    E.SaldoVacaciones = (
               SELECT TOP 1 M.NuevoSaldo
               FROM   dbo.Movimiento M
               WHERE  (M.IdEmpleado = E.Id)
               ORDER BY M.Fecha DESC, M.PostTime DESC
             )
      FROM   dbo.Empleado E
      WHERE  EXISTS (
               SELECT 1 FROM dbo.Movimiento M
               WHERE  (M.IdEmpleado = E.Id)
               AND    (M.Fecha = @vFechaActual)
             );

      DELETE FROM @vFechas WHERE (Fecha = @vFechaActual);
    END

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