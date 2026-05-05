USE mi_db;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_listar_empleados
  @inFiltro      VARCHAR(128) = NULL
, @outResultCode INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  BEGIN TRY
    IF (@inFiltro IS NOT NULL AND LTRIM(RTRIM(@inFiltro)) = '')
      SET @inFiltro = NULL;

    SELECT E.Id
         , E.ValorDocumentoIdentidad
         , E.Nombre
         , P.Nombre      AS Puesto
         , E.SaldoVacaciones
         , E.EsActivo
    FROM   dbo.Empleado E
    JOIN   dbo.Puesto   P ON (P.Id = E.IdPuesto)
    WHERE  (E.EsActivo = 1)
    AND    (
             @inFiltro IS NULL
             -- Solo letras y espacios: busca por nombre
             OR (@inFiltro NOT LIKE '%[0-9]%'  AND E.Nombre LIKE '%' + @inFiltro + '%')
             -- Solo números: busca por cedula
             OR (@inFiltro NOT LIKE '%[^0-9]%' AND E.ValorDocumentoIdentidad LIKE '%' + @inFiltro + '%')
           )
    ORDER BY E.Nombre ASC;

    SET @outResultCode = 0;
  END TRY
  BEGIN CATCH
    SET @outResultCode = ERROR_NUMBER() + 50000;
    INSERT INTO dbo.DBError (UserName, Number, State, Severity, Line, [Procedure], Message, DateTime)
    VALUES (SUSER_SNAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(),
            ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE(), GETDATE());
    THROW;
  END CATCH
END;
GO