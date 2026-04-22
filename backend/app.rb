require 'sinatra'
require 'sinatra/reloader' if development?
require_relative 'config/database'

# Configuración Docker
set :bind, '0.0.0.0'
set :port, 3000
set :public_folder, '/frontend' 

def contar(tabla)
  Database.query do |db|
    resultado = db.execute("SELECT COUNT(*) AS c FROM dbo.#{tabla}")
    fila = resultado.first
    puts "DEBUG #{tabla} — fila.class: #{fila.class}, fila.inspect: #{fila.inspect}"
    fila.values.first.to_i
  end
end

# Ruta raíz
get '/' do
  send_file File.join(settings.public_folder, 'index.html')
end

# Ruta de carga de xml
post '/cargar-xml' do
  unless params[:archivo_xml]
    return "<div style='color:red'>Error: No se seleccionó ningún archivo.</div>"
  end
 
  xml_content = params[:archivo_xml][:tempfile].read
  xml_content = xml_content.sub(/\A<\?xml[^?]*\?>/, '').strip
  xml_escaped  = xml_content.gsub("'", "''")
 
  # Construir el batch ANTES del bloque para evitar problemas de scope
  sql_batch = "SET QUOTED_IDENTIFIER ON; " \
              "SET ANSI_NULLS ON; " \
              "SET ANSI_PADDING ON; " \
              "SET ANSI_WARNINGS ON; " \
              "SET ARITHABORT ON; " \
              "SET CONCAT_NULL_YIELDS_NULL ON; " \
              "SET NUMERIC_ROUNDABORT OFF; " \
              "EXEC dbo.sp_carga_xml @xml = N'#{xml_escaped}';"
 
  begin
    Database.query do |db|
      db.execute(sql_batch).do
    end
 
    puestos     = contar('Puesto')
    empleados   = contar('Empleado')
    movimientos = contar('Movimiento')

    # Respuesta de exito
    resultado_html = "<div style='background:#dcfce7;color:#15803d;padding:20px;border-radius:8px;border:1px solid #22c55e'>" \
  "<h3 style='margin-top:0'>Exito</h3>" \
  "<p>El archivo se procesó completo y sin fallas.</p>" \
  "<ul style='margin-bottom:0'>" \
  "<li>Puestos en catálogo: #{puestos}</li>" \
  "<li>Empleados registrados: #{empleados}</li>" \
  "<li>Movimientos procesados: #{movimientos}</li>" \
  "</ul></div>"

  puts "DEBUG HTML: #{resultado_html}"
  resultado_html

  
  rescue => e
    # Imprimir el error en la terminal
    puts "Error: #{e.message}"

    # Enviar error al htmx
    "
    <div style='background: #fee2e2; color: #b91c1c; padding: 20px; border-radius: 8px; border: 1px solid #ef4444;'>
      <strong>Error:</strong>
      <p>#{e.message}</p>
    </div>
    "
  end
end