require 'sinatra'
require 'sinatra/reloader' if development?
require_relative 'config/database'

set :bind, '0.0.0.0'
set :port, 3000
set :public_folder, '/frontend'
VIEWS = '/frontend/views'

SESSION_SECRET = ENV.fetch('SESSION_SECRET',
  'LaContraseñaTieneQueExcederSesentayCuatroCaracteresParaSerQueRubyLaAcepte')

use Rack::Session::Cookie,
  key:          'tarea2.session',
  secret:       SESSION_SECRET,
  expire_after: 3600

def contar(tabla)
  Database.query do |db|
    db.execute("SELECT COUNT(*) AS c FROM dbo.#{tabla}").first.values.first.to_i
  end
end

def require_login
  redirect '/login' unless session[:usuario]
end

# Rutas Publicas

get '/login' do
  redirect '/' if session[:usuario]
  File.read("#{VIEWS}/login.html")
end

get '/setup' do
  File.read("#{VIEWS}/setup.html")
end
 
post '/cargar-xml' do
  unless params[:archivo_xml]
    return "<div style='color:#f87171'>Error: No se seleccionó ningún archivo.</div>"
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

    "<div style='background:#052e16;color:#4ade80;padding:1rem;border:1px solid #166534;border-radius:4px'>" \
    "<strong>Carga exitosa.</strong> " \
    "#{puestos} puestos · #{empleados} empleados · #{movimientos} movimientos." \
    "<br><br><a href='/login' style='color:#00d4ff;font-size:0.85rem'>→ Ir al login</a>" \
    "</div>"
  rescue => e
    puts "ERROR carga XML: #{e.message}"
    "<div style='background:#2a0a0a;color:#f87171;padding:1rem;border:1px solid #7f1d1d;border-radius:4px'>" \
    "<strong>Error:</strong> #{e.message}</div>"
  end
end

# Rutas protegidas (login requerido)

get '/' do
  require_login
  File.read("#{VIEWS}/index.html")
end

require_relative 'controllers/sesion_controller'
require_relative 'controllers/empleados_controller'