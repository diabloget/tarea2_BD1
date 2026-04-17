require 'tiny_tds'

#Unica sección del código que sabe como conectarse a la DB
module Database
  def self.conectar
    TinyTds::Client.new(
      host:     ENV.fetch('DB_HOST', 'localhost'),
      port:     1433,
      username: 'sa',
      password: ENV.fetch('DB_PASSWORD', 'Bd1tarea!'),
      database: 'mi_db'
    )
  end

  # Abre conexión, ejecuta el bloque y la cierra aunque ocurra un error.
  # Uso: Database.query { |db| db.execute("EXEC ...") }
  def self.query
    db = conectar
    yield db
  ensure
    db&.close
  end
end
