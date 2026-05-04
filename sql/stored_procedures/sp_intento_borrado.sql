USE mi_db;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_intento_borrado
  @Id           INT,
  @IdPostByUser INT,
  @PostInIP     VARCHAR(45)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @Cedula VARCHAR(20);
  DECLARE @Nombre VARCHAR(128);
  DECLARE @Puesto VARCHAR(128);
  DECLARE @Saldo  DECIMAL(10,2);

  SELECT
    @Cedula = e.ValorDocumentoIdentidad,
    @Nombre = e.Nombre,
    @Puesto = p.Nombre,
    @Saldo  = e.SaldoVacaciones
  FROM dbo.Empleado AS e
  JOIN dbo.Puesto   AS p ON p.Id = e.IdPuesto
  WHERE e.Id = @Id;

  INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP, PostTime)
  VALUES (9,
    'Cédula: ' + ISNULL(@Cedula,'') + ' | Nombre: ' + ISNULL(@Nombre,'') +
    ' | Puesto: ' + ISNULL(@Puesto,'') + ' | Saldo: ' + CAST(ISNULL(@Saldo,0) AS VARCHAR),
    @IdPostByUser, @PostInIP, GETDATE());
END;
GO