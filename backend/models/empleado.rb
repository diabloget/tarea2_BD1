require_relative '../config/database'

class Empleado
  def self.todos(filtro: nil)
    Database.query do |db|
      filtro_escaped = filtro.to_s.strip.gsub("'", "''")
      sql = if filtro_escaped.empty?
        "EXEC dbo.sp_listar_empleados"
      else
        "EXEC dbo.sp_listar_empleados @Filtro = N'#{filtro_escaped}'"
      end
      db.execute(sql).map { |fila| fila }
    end
  end
end