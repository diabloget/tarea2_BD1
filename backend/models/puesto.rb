require_relative '../config/database'

class Puesto
  def self.todos
    Database.query do |db|
      db.execute(
        "DECLARE @outResultCode INT; EXEC dbo.sp_listar_puestos @outResultCode = @outResultCode OUTPUT;"
      ).map { |f| f }
    end
  end
end