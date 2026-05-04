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

  def self.buscar(id:)
    Database.query do |db|
      db.execute("EXEC dbo.sp_consultar_empleado @Id = #{id.to_i}").first
    end
  end

  def self.crear(cedula:, nombre:, id_puesto:, fecha_contratacion:, id_usuario:, ip:)
    Database.query do |db|
      sql = "DECLARE @Codigo INT; " \
            "EXEC dbo.sp_insertar_empleado " \
            "  @ValorDocumentoIdentidad = N'#{cedula.gsub("'","''")}', " \
            "  @Nombre                  = N'#{nombre.gsub("'","''")}', " \
            "  @IdPuesto                = #{id_puesto.to_i}, " \
            "  @FechaContratacion       = '#{fecha_contratacion}', " \
            "  @IdPostByUser            = #{id_usuario.to_i}, " \
            "  @PostInIP                = N'#{ip}', " \
            "  @Codigo                  = @Codigo OUTPUT; " \
            "SELECT @Codigo AS Codigo;"
      db.execute(sql).first&.values&.first.to_i
    end
  end

  def self.actualizar(id:, cedula:, nombre:, id_puesto:, id_usuario:, ip:)
    Database.query do |db|
      sql = "DECLARE @Codigo INT; " \
            "EXEC dbo.sp_actualizar_empleado " \
            "  @Id                      = #{id.to_i}, " \
            "  @ValorDocumentoIdentidad = N'#{cedula.gsub("'","''")}', " \
            "  @Nombre                  = N'#{nombre.gsub("'","''")}', " \
            "  @IdPuesto                = #{id_puesto.to_i}, " \
            "  @IdPostByUser            = #{id_usuario.to_i}, " \
            "  @PostInIP                = N'#{ip}', " \
            "  @Codigo                  = @Codigo OUTPUT; " \
            "SELECT @Codigo AS Codigo;"
      db.execute(sql).first&.values&.first.to_i
    end
  end

  def self.borrar(id:, id_usuario:, ip:)
    Database.query do |db|
      db.execute(
        "EXEC dbo.sp_borrar_empleado " \
        "  @Id = #{id.to_i}, " \
        "  @IdPostByUser = #{id_usuario.to_i}, " \
        "  @PostInIP = N'#{ip}'"
      ).do
    end
  end

  def self.registrar_intento_borrado(id:, id_usuario:, ip:)
    Database.query do |db|
      db.execute(
        "EXEC dbo.sp_intento_borrado " \
        "  @Id = #{id.to_i}, " \
        "  @IdPostByUser = #{id_usuario.to_i}, " \
        "  @PostInIP = N'#{ip}'"
      ).do
    end
  end
end