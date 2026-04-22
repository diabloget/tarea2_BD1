-- sp_carga_xml.sql
USE mi_db;
GO

CREATE OR ALTER PROCEDURE dbo.sp_carga_xml
  @xml XML
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    BEGIN TRANSACTION;

    -- Carga de puestos
    INSERT INTO dbo.Puesto (Nombre, SalarioxHora)
    SELECT
      x.value('@Nombre', 'VARCHAR(128)'),
      x.value('@SalarioxHora', 'MONEY')
    FROM @xml.nodes('/Datos/Puestos/Puesto') AS T(x);

    -- Carga de tipos de movimientos
    INSERT INTO dbo.TipoMovimiento (Id, Nombre, TipoAccion)
    SELECT
      x.value('@Id', 'INT'),
      x.value('@Nombre', 'VARCHAR(128)'),
      x.value('@TipoAccion', 'VARCHAR(10)')
    FROM @xml.nodes('/Datos/TiposMovimientos/TipoMovimiento') AS T(x);

    -- Carga de empleados
    INSERT INTO dbo.Empleado (IdPuesto, ValorDocumentoIdentidad, Nombre, FechaContratacion, SaldoVacaciones, EsActivo)
    SELECT
      (SELECT Id FROM dbo.Puesto WHERE Nombre = x.value('@Puesto', 'VARCHAR(128)')),
      x.value('@ValorDocumentoIdentidad', 'VARCHAR(20)'),
      x.value('@Nombre', 'VARCHAR(128)'),
      x.value('@FechaContratacion', 'DATE'),
      0, 1
    FROM @xml.nodes('/Datos/Empleados/empleado') AS T(x);

    COMMIT TRANSACTION;
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
  END CATCH
END;
GO