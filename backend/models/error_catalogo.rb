require_relative '../config/database'

class ErrorCatalogo
  def self.descripcion(codigo)
    Database.query do |db|
      resultado = db.execute("EXEC dbo.sp_obtener_error @Codigo = #{codigo.to_i}").first
      resultado ? resultado['Descripcion'] : "Error desconocido (código #{codigo})"
    end
  rescue
    "Error desconocido (código #{codigo})"
  end
end