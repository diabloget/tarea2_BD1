require 'sinatra'
require 'sinatra/reloader' if development?
require_relative 'config/database'
 
set :bind, '0.0.0.0'
set :port, 3000
set :public_folder, '/frontend'
 
get '/' do
  send_file File.join(settings.public_folder, 'index.html')
end
 
post '/cargar-xml' do
  xml_content = params[:archivo_xml][:tempfile].read
 
  begin
    # El SP recibe el XML como parámetro tipado.
    # gsub escapa comillas simples para no romper el string T-SQL.
    Database.query do |db|
      db.execute("EXEC dbo.sp_carga_xml @xml = N'#{xml_content.gsub("'", "''")}'").do
    end
 
    # Las consultas de conteo van en conexiones separadas porque
    # TinyTDS no permite reusar la misma conexión tras un .do
    puestos   = Database.query { |db| db.execute("SELECT COUNT(*) AS c FROM dbo.Puesto").first['c'] }
    empleados = Database.query { |db| db.execute("SELECT COUNT(*) AS c FROM dbo.Empleado").first['c'] }
 
    "<div style='color:green'>✓ Carga exitosa: #{puestos} puestos y #{empleados} empleados.</div>"
  rescue => e
    puts "ERROR: #{e.message}"
    "<div style='color:red'>✗ Error: #{e.message}</div>"
  end
end