require_relative '../config/database'

class Puesto
  def self.todos
    Database.query do |db|
      db.execute("EXEC dbo.sp_listar_puestos").map { |f| f }
    end
  end
end