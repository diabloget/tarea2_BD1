USE mi_db;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_listar_empleados
  @Filtro VARCHAR(128) = NULL  
AS
BEGIN
  SET NOCOUNT ON;
  IF @Filtro IS NOT NULL AND LTRIM(RTRIM(@Filtro)) = ''
    SET @Filtro = NULL;

  SELECT
    e.Id,
    e.ValorDocumentoIdentidad,
    e.Nombre,
    p.Nombre       AS Puesto,
    e.SaldoVacaciones,
    e.EsActivo
  FROM dbo.Empleado AS e
  JOIN dbo.Puesto   AS p ON p.Id = e.IdPuesto
  WHERE e.EsActivo = 1
    AND (
      @Filtro IS NULL
      -- Solo letras y espacios: busca por nombre
      OR (@Filtro NOT LIKE '%[0-9]%' AND e.Nombre LIKE '%' + @Filtro + '%')
      -- Solo números: busca por cedula
      OR (@Filtro NOT LIKE '%[^0-9]%' AND e.ValorDocumentoIdentidad LIKE '%' + @Filtro + '%')
    )
  ORDER BY e.Nombre ASC;
END;
GO