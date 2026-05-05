require_relative '../config/database'

class Movimiento
  def self.por_empleado(id_empleado:)
    Database.query do |db|
      db.execute(
        "DECLARE @outResultCode INT; " \
        "EXEC dbo.sp_listar_movimientos @inIdEmpleado = #{id_empleado.to_i}, @outResultCode = @outResultCode OUTPUT;"
      ).map { |f| f }
    end
  end

  def self.tipos
    Database.query do |db|
      db.execute(
        "DECLARE @outResultCode INT; EXEC dbo.sp_listar_tipos_movimiento @outResultCode = @outResultCode OUTPUT;"
      ).map { |f| f }
    end
  end

  def self.insertar(id_empleado:, id_tipo:, monto:, id_usuario:, ip:)
    Database.query do |db|
      sql = "DECLARE @outResultCode INT; " \
            "EXEC dbo.sp_insertar_movimiento " \
            "  @inIdEmpleado       = #{id_empleado.to_i}, " \
            "  @inIdTipoMovimiento = #{id_tipo.to_i}, " \
            "  @inMonto            = #{monto.to_f}, " \
            "  @inIdPostByUser     = #{id_usuario.to_i}, " \
            "  @inPostInIP         = N'#{ip}', " \
            "  @outResultCode      = @outResultCode OUTPUT; " \
            "SELECT @outResultCode AS Codigo;"
      db.execute(sql).first&.values&.first.to_i
    end
  end
end