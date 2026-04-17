require 'sinatra'
require 'sinatra/reloader' if development?

# Server
set :port, 3000
set :bind, '0.0.0.0'

# Sesiones para login/logout (secret debe moverse a variable de entorno despuesito)
use Rack::Session::Cookie, secret: ENV.fetch('SESSION_SECRET', 'cambiar_en_produccion')

# Sinatra sirve el frontend como archivos estáticos
set :public_folder, File.join(__dir__, '..', 'frontend')

get '/' do
  # aqui falta lo de redirigir a /login si no hay sesión activa
  send_file File.join(settings.public_folder, 'index.html')
end


require_relative 'controllers/sesion_controller'
require_relative 'controllers/empleados_controller'
require_relative 'controllers/movimientos_controller'