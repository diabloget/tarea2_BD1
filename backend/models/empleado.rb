require_relative '../config/database'

class Empleado
  def self.todos(filtro: nil)
    Database.query do |db|
      filtro_escaped = filtro.to_s.strip.gsub("'", "''")
      sql = filtro_escaped.empty? \
        ? "EXEC dbo.sp_listar_empleados" \
        : "EXEC dbo.sp_listar_empleados @Filtro = N'#{filtro_escaped}'"
      db.execute(sql).map { |f| f }
    end
  end

  def self.crear(cedula:, nombre:, id_puesto:, fecha_contratacion:, id_usuario:, ip:)
    Database.query do |db|
      sql = "DECLARE @Codigo INT; " \
            "EXEC dbo.sp_insertar_empleado " \
            "  @ValorDocumentoIdentidad = N'#{cedula.gsub("'", "''")}', " \
            "  @Nombre                  = N'#{nombre.gsub("'", "''")}', " \
            "  @IdPuesto                = #{id_puesto.to_i}, " \
            "  @FechaContratacion       = '#{fecha_contratacion}', " \
            "  @IdPostByUser            = #{id_usuario.to_i}, " \
            "  @PostInIP                = N'#{ip}', " \
            "  @Codigo                  = @Codigo OUTPUT; " \
            "SELECT @Codigo AS Codigo;"
      db.execute(sql).first&.values&.first.to_i
    end
  end
end