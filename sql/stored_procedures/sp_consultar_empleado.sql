USE mi_db;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_consultar_empleado
  @Id INT
AS
BEGIN
  SET NOCOUNT ON;
  SELECT
    e.Id,
    e.ValorDocumentoIdentidad,
    e.Nombre,
    e.IdPuesto,
    p.Nombre      AS Puesto,
    e.FechaContratacion,
    e.SaldoVacaciones
  FROM dbo.Empleado AS e
  JOIN dbo.Puesto   AS p ON p.Id = e.IdPuesto
  WHERE e.Id = @Id AND e.EsActivo = 1;
END;
GO