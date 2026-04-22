USE mi_db;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_carga_xml
  @xml XML
AS
BEGIN
  SET NOCOUNT ON;

  BEGIN TRY
    BEGIN TRANSACTION;

    -- Puestos
    INSERT INTO dbo.Puesto (Nombre, SalarioxHora)
    SELECT
      x.value('@Nombre',       'VARCHAR(128)'),
      x.value('@SalarioxHora', 'MONEY')
    FROM @xml.nodes('/Datos/Puestos/Puesto') AS T(x);

    -- TiposMovimiento
    INSERT INTO dbo.TipoMovimiento (Id, Nombre, TipoAccion)
    SELECT
      x.value('@Id',         'INT'),
      x.value('@Nombre',     'VARCHAR(128)'),
      x.value('@TipoAccion', 'VARCHAR(10)')
    FROM @xml.nodes('/Datos/TiposMovimientos/TipoMovimiento') AS T(x);

    -- TiposEvento
    INSERT INTO dbo.TipoEvento (Id, Nombre)
    SELECT
      x.value('@Id',     'INT'),
      x.value('@Nombre', 'VARCHAR(128)')
    FROM @xml.nodes('/Datos/TiposEvento/TipoEvento') AS T(x);

    -- Usuarios (UsuarioScripts tiene Id duplicado en el XML, se fuerza a 0)
    INSERT INTO dbo.Usuario (Id, Username, Password)
    VALUES (0, 'UsuarioScripts', 'UsuarioScripts');

    INSERT INTO dbo.Usuario (Id, Username, Password)
    SELECT
      x.value('@Id',     'INT'),
      x.value('@Nombre', 'VARCHAR(64)'),
      x.value('@Pass',   'VARCHAR(128)')
    FROM @xml.nodes('/Datos/Usuarios/usuario') AS T(x)
    WHERE x.value('@Nombre', 'VARCHAR(64)') <> 'UsuarioScripts';

    -- Errores
    INSERT INTO dbo.Error (Codigo, Descripcion)
    SELECT
      x.value('@Codigo',      'INT'),
      x.value('@Descripcion', 'VARCHAR(256)')
    FROM @xml.nodes('/Datos/Error/error') AS T(x);

    -- Empleados (Puesto viene como nombre -> lookup)
    INSERT INTO dbo.Empleado (IdPuesto, ValorDocumentoIdentidad, Nombre, FechaContratacion, SaldoVacaciones, EsActivo)
    SELECT
      (SELECT Id FROM dbo.Puesto WHERE Nombre = x.value('@Puesto', 'VARCHAR(128)')),
      x.value('@ValorDocumentoIdentidad', 'VARCHAR(20)'),
      x.value('@Nombre',                  'VARCHAR(128)'),
      x.value('@FechaContratacion',       'DATE'),
      0, 1
    FROM @xml.nodes('/Datos/Empleados/empleado') AS T(x);

    -- Movimientos con NuevoSaldo acumulado por empleado
    ;WITH Parseados AS (
      SELECT
        (SELECT Id FROM dbo.Empleado       WHERE ValorDocumentoIdentidad = x.value('@ValorDocId',       'VARCHAR(20)'))  AS IdEmpleado,
        (SELECT Id FROM dbo.TipoMovimiento WHERE Nombre                  = x.value('@IdTipoMovimiento', 'VARCHAR(128)')) AS IdTipoMovimiento,
        (SELECT TipoAccion FROM dbo.TipoMovimiento WHERE Nombre          = x.value('@IdTipoMovimiento', 'VARCHAR(128)')) AS TipoAccion,
        x.value('@Fecha',    'DATE')          AS Fecha,
        x.value('@Monto',    'DECIMAL(10,2)') AS Monto,
        (SELECT Id FROM dbo.Usuario WHERE Username = x.value('@PostByUser', 'VARCHAR(64)'))                              AS IdPostByUser,
        x.value('@PostInIP', 'VARCHAR(45)')   AS PostInIP,
        x.value('@PostTime', 'DATETIME')      AS PostTime
      FROM @xml.nodes('/Datos/Movimientos/movimiento') AS T(x)
    ),
    ConSaldo AS (
      SELECT
        IdEmpleado, IdTipoMovimiento, Fecha, Monto,
        SUM(CASE WHEN TipoAccion = 'Credito' THEN Monto ELSE -Monto END)
          OVER (
            PARTITION BY IdEmpleado
            ORDER BY Fecha, PostTime
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
          ) AS NuevoSaldo,
        IdPostByUser, PostInIP, PostTime
      FROM Parseados
    )
    INSERT INTO dbo.Movimiento (IdEmpleado, IdTipoMovimiento, Fecha, Monto, NuevoSaldo, IdPostByUser, PostInIP, PostTime)
    SELECT IdEmpleado, IdTipoMovimiento, Fecha, Monto, NuevoSaldo, IdPostByUser, PostInIP, PostTime
    FROM ConSaldo;

    -- Actualizar SaldoVacaciones con el último movimiento de cada empleado
    UPDATE e
    SET e.SaldoVacaciones = (
      SELECT TOP 1 m.NuevoSaldo
      FROM dbo.Movimiento AS m
      WHERE m.IdEmpleado = e.Id
      ORDER BY m.Fecha DESC, m.PostTime DESC
    )
    FROM dbo.Empleado AS e
    WHERE EXISTS (SELECT 1 FROM dbo.Movimiento AS m WHERE m.IdEmpleado = e.Id);

    COMMIT TRANSACTION;

  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    INSERT INTO dbo.DBError (UserName, Number, State, Severity, Line, [Procedure], Message, DateTime)
    VALUES (
      SUSER_SNAME(),
      ERROR_NUMBER(),
      ERROR_STATE(),
      ERROR_SEVERITY(),
      ERROR_LINE(),
      ERROR_PROCEDURE(),
      ERROR_MESSAGE(),
      GETDATE()
    );

    THROW;
  END CATCH
END;
GO