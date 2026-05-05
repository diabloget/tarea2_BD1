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

def no_cache
  headers 'Cache-Control' => 'no-store, no-cache, must-revalidate',
          'Pragma'         => 'no-cache',
          'Expires'        => '0'
end

# Rutas públicas

get '/login' do
  no_cache
  redirect '/' if session[:usuario]
  error_msg = session.delete(:login_error)
  html = File.read("#{VIEWS}/login.html")
  error_msg ? html.sub('id="login-error"', "id='login-error' style='display:block'").sub('LOGIN_ERROR', error_msg) : html
end

get '/setup' do
  File.read("#{VIEWS}/setup.html")
end

post '/cargar-xml' do
  unless params[:archivo_xml]
    return "<div style='color:#9b3a3a'>Error: no se seleccionó ningún archivo.</div>"
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
    "<div style='color:#2d5a4e;font-size:0.85rem'>" \
    "Carga completada — #{puestos} puestos · #{empleados} empleados · #{movimientos} movimientos." \
    "</div>"
  rescue => e
    puts "ERROR carga XML: #{e.message}"
    "<div style='color:#9b3a3a;font-size:0.85rem'>Error: #{e.message}</div>"
  end
end

# Rutas protegidas (login) 

get '/' do
  require_login
  no_cache
  File.read("#{VIEWS}/index.html")
end

require_relative 'controllers/sesion_controller'
require_relative 'controllers/empleados_controller'
require_relative 'controllers/movimientos_controller'