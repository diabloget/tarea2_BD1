require_relative '../config/database'

class Movimiento
  def self.por_empleado(id_empleado:)
    Database.query do |db|
      db.execute("EXEC dbo.sp_listar_movimientos @IdEmpleado = #{id_empleado.to_i}").map { |f| f }
    end
  end

  def self.tipos
    Database.query do |db|
      db.execute("EXEC dbo.sp_listar_tipos_movimiento").map { |f| f }
    end
  end

  def self.insertar(id_empleado:, id_tipo:, monto:, id_usuario:, ip:)
    Database.query do |db|
      sql = "DECLARE @Codigo INT; " \
            "EXEC dbo.sp_insertar_movimiento " \
            "  @IdEmpleado       = #{id_empleado.to_i}, " \
            "  @IdTipoMovimiento = #{id_tipo.to_i}, " \
            "  @Monto            = #{monto.to_f}, " \
            "  @IdPostByUser     = #{id_usuario.to_i}, " \
            "  @PostInIP         = N'#{ip}', " \
            "  @Codigo           = @Codigo OUTPUT; " \
            "SELECT @Codigo AS Codigo;"
      db.execute(sql).first&.values&.first.to_i
    end
  end
end