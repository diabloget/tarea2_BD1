require 'sinatra'
require 'sinatra/reloader' if development?
require_relative 'config/database'

set :bind, '0.0.0.0'
set :port, 3000
set :public_folder, '/frontend'

# Sesiones para login/logout
use Rack::Session::Cookie,
  key:    'tarea2.session',
  secret: ENV.fetch('SESSION_SECRET', 'cambiar_en_produccion'),
  expire_after: 3600

# Helper para contar filas 
def contar(tabla)
  Database.query do |db|
    db.execute("SELECT COUNT(*) AS c FROM dbo.#{tabla}").first.values.first.to_i
  end
end

# Helper de autenticación
def require_login
  redirect '/login' unless session[:usuario]
end

# Página principal
get '/' do
  require_login
  send_file File.join(settings.public_folder, 'index.html')
end

# Carga de XML
post '/cargar-xml' do
  require_login

  unless params[:archivo_xml]
    return "<div style='color:red'>Error: No se seleccionó ningún archivo.</div>"
  end

  xml_content = params[:archivo_xml][:tempfile].read
  xml_content = xml_content.sub(/\A<\?xml[^?]*\?>/, '').strip
  xml_escaped = xml_content.gsub("'", "''")

  sql_batch = "SET QUOTED_IDENTIFIER ON; " \
              "SET ANSI_NULLS ON; " \
              "SET ANSI_PADDING ON; " \
              "SET ANSI_WARNINGS ON; " \
              "SET ARITHABORT ON; " \
              "SET CONCAT_NULL_YIELDS_NULL ON; " \
              "SET NUMERIC_ROUNDABORT OFF; " \
              "EXEC dbo.sp_carga_xml @xml = N'#{xml_escaped}';"

  begin
    Database.query { |db| db.execute(sql_batch).do }

    puestos     = contar('Puesto')
    empleados   = contar('Empleado')
    movimientos = contar('Movimiento')

    "<div style='background:#dcfce7;color:#15803d;padding:20px;border-radius:8px;border:1px solid #22c55e'>" \
    "<h3 style='margin-top:0'>Exito</h3>" \
    "<p>El archivo se procesó completo y sin fallas.</p>" \
    "<ul style='margin-bottom:0'>" \
    "<li>Puestos en catálogo: #{puestos}</li>" \
    "<li>Empleados registrados: #{empleados}</li>" \
    "<li>Movimientos procesados: #{movimientos}</li>" \
    "</ul></div>"
  rescue => e
    puts "ERROR: #{e.message}"
    "<div style='background:#fee2e2;color:#b91c1c;padding:20px;border-radius:8px;border:1px solid #ef4444'>" \
    "<strong>Error:</strong><p>#{e.message}</p></div>"
  end
end

require_relative 'controllers/sesion_controller'
require_relative 'controllers/empleados_controller'