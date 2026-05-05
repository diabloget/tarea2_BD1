require_relative '../config/database'

class Empleado
  def self.todos(filtro: nil)
    Database.query do |db|
      filtro_escaped = filtro.to_s.strip.gsub("'", "''")
      sql = if filtro_escaped.empty?
        "DECLARE @outResultCode INT; EXEC dbo.sp_listar_empleados @outResultCode = @outResultCode OUTPUT;"
      else
        "DECLARE @outResultCode INT; EXEC dbo.sp_listar_empleados @inFiltro = N'#{filtro_escaped}', @outResultCode = @outResultCode OUTPUT;"
      end
      db.execute(sql).map { |f| f }
    end
  end

  def self.buscar(id:)
    Database.query do |db|
      db.execute(
        "DECLARE @outResultCode INT; " \
        "EXEC dbo.sp_consultar_empleado @inId = #{id.to_i}, @outResultCode = @outResultCode OUTPUT;"
      ).first
    end
  end

  def self.crear(cedula:, nombre:, id_puesto:, fecha_contratacion:, id_usuario:, ip:)
    Database.query do |db|
      sql = "DECLARE @outResultCode INT; " \
            "EXEC dbo.sp_insertar_empleado " \
            "  @inValorDocumentoIdentidad = N'#{cedula.gsub("'","''")}', " \
            "  @inNombre                  = N'#{nombre.gsub("'","''")}', " \
            "  @inIdPuesto                = #{id_puesto.to_i}, " \
            "  @inFechaContratacion       = '#{fecha_contratacion}', " \
            "  @inIdPostByUser            = #{id_usuario.to_i}, " \
            "  @inPostInIP                = N'#{ip}', " \
            "  @outResultCode             = @outResultCode OUTPUT; " \
            "SELECT @outResultCode AS Codigo;"
      db.execute(sql).first&.values&.first.to_i
    end
  end

  def self.actualizar(id:, cedula:, nombre:, id_puesto:, id_usuario:, ip:)
    Database.query do |db|
      sql = "DECLARE @outResultCode INT; " \
            "EXEC dbo.sp_actualizar_empleado " \
            "  @inId                      = #{id.to_i}, " \
            "  @inValorDocumentoIdentidad = N'#{cedula.gsub("'","''")}', " \
            "  @inNombre                  = N'#{nombre.gsub("'","''")}', " \
            "  @inIdPuesto                = #{id_puesto.to_i}, " \
            "  @inIdPostByUser            = #{id_usuario.to_i}, " \
            "  @inPostInIP                = N'#{ip}', " \
            "  @outResultCode             = @outResultCode OUTPUT; " \
            "SELECT @outResultCode AS Codigo;"
      db.execute(sql).first&.values&.first.to_i
    end
  end

  def self.borrar(id:, id_usuario:, ip:)
    Database.query do |db|
      db.execute(
        "DECLARE @outResultCode INT; " \
        "EXEC dbo.sp_borrar_empleado " \
        "  @inId           = #{id.to_i}, " \
        "  @inIdPostByUser = #{id_usuario.to_i}, " \
        "  @inPostInIP     = N'#{ip}', " \
        "  @outResultCode  = @outResultCode OUTPUT;"
      ).do
    end
  end

  def self.registrar_intento_borrado(id:, id_usuario:, ip:)
    Database.query do |db|
      db.execute(
        "DECLARE @outResultCode INT; " \
        "EXEC dbo.sp_intento_borrado " \
        "  @inId           = #{id.to_i}, " \
        "  @inIdPostByUser = #{id_usuario.to_i}, " \
        "  @inPostInIP     = N'#{ip}', " \
        "  @outResultCode  = @outResultCode OUTPUT;"
      ).do
    end
  end
end