require_relative '../models/empleado'
require_relative '../models/puesto'
require_relative '../models/error_catalogo'

def msg_error(codigo)
  "<span style='color:#9b3a3a'>#{ErrorCatalogo.descripcion(codigo)}</span>"
end

def msg_ok(texto)
  "<span style='color:#2d5a4e'>#{texto}</span>"
end

get '/api/empleados' do
  unless session[:usuario]
    return '<tr><td colspan="5" style="text-align:center;color:#9b3a3a;padding:1rem;">
      Sesión expirada. <a href="/login" style="color:#2d5a4e">Ingresar</a></td></tr>'
  end

  filtro    = params[:filtro].to_s.strip
  empleados = Empleado.todos(filtro: filtro.empty? ? nil : filtro)

  if empleados.empty?
    return '<tr class="empty-row"><td colspan="5">Sin registros.</td></tr>'
  end

  empleados.map do |e|
    id             = e['Id']
    saldo          = '%.2f' % e['SaldoVacaciones'].to_f
    nombre_escaped = e['Nombre'].gsub("'", "\\'").gsub('"', '&quot;')
    "<tr>
      <td>#{e['ValorDocumentoIdentidad']}</td>
      <td>#{e['Nombre']}</td>
      <td>#{e['Puesto']}</td>
      <td>#{saldo}</td>
      <td class='td-acciones'>
        <button class='btn-accion' onclick='abrirConsulta(#{id})'>Ver</button>
        <button class='btn-accion' onclick='abrirMovimientos(#{id})'>Movimientos</button>
        <button class='btn-accion' onclick='abrirEditar(#{id})'>Editar</button>
        <button class='btn-accion' onclick='confirmarBorrado(#{id},\"#{nombre_escaped}\",\"#{e['ValorDocumentoIdentidad']}\")'>Borrar</button>
      </td>
    </tr>"
  end.join
end

get '/api/puestos' do
  halt 401 unless session[:usuario]
  Puesto.todos.map { |p| "<option value='#{p['Id']}'>#{p['Nombre']}</option>" }.join
end

get '/api/empleados/:id' do
  halt 401 unless session[:usuario]
  e = Empleado.buscar(id: params[:id])
  halt 404 unless e
  content_type :json
  { id: e['Id'], cedula: e['ValorDocumentoIdentidad'], nombre: e['Nombre'],
    id_puesto: e['IdPuesto'], puesto: e['Puesto'],
    fecha: e['FechaContratacion'].to_s, saldo: '%.2f' % e['SaldoVacaciones'].to_f }.to_json
end

post '/api/empleados' do
  halt 401 unless session[:usuario]

  cedula    = params[:cedula].to_s.strip
  nombre    = params[:nombre].to_s.strip
  id_puesto = params[:id_puesto].to_s.strip
  fecha     = params[:fecha_contratacion].to_s.strip

  if cedula.empty? || nombre.empty? || id_puesto.empty? || fecha.empty?
    return msg_error(0).sub('Error desconocido (código 0)', 'Todos los campos son requeridos.')
  end
  unless cedula.match?(/\A\d+\z/)
    return msg_error(50010)
  end
  unless nombre.match?(/\A[A-Za-záéíóúÁÉÍÓÚñÑüÜ\s\-]+\z/)
    return msg_error(50009)
  end

  codigo = Empleado.crear(cedula: cedula, nombre: nombre, id_puesto: id_puesto,
    fecha_contratacion: fecha, id_usuario: session[:usuario_id], ip: request.ip)

  if codigo == 0
    headers 'HX-Trigger' => 'empleadosActualizado'
    msg_ok('Empleado insertado correctamente.')
  else
    msg_error(codigo)
  end
end

put '/api/empleados/:id' do
  halt 401 unless session[:usuario]

  cedula    = params[:cedula].to_s.strip
  nombre    = params[:nombre].to_s.strip
  id_puesto = params[:id_puesto].to_s.strip

  if cedula.empty? || nombre.empty? || id_puesto.empty?
    return msg_error(0).sub('Error desconocido (código 0)', 'Todos los campos son requeridos.')
  end
  unless cedula.match?(/\A\d+\z/)
    return msg_error(50010)
  end
  unless nombre.match?(/\A[A-Za-záéíóúÁÉÍÓÚñÑüÜ\s\-]+\z/)
    return msg_error(50009)
  end

  codigo = Empleado.actualizar(id: params[:id], cedula: cedula, nombre: nombre,
    id_puesto: id_puesto, id_usuario: session[:usuario_id], ip: request.ip)

  if codigo == 0
    headers 'HX-Trigger' => 'empleadosActualizado'
    msg_ok('Empleado actualizado correctamente.')
  else
    msg_error(codigo)
  end
end

delete '/api/empleados/:id' do
  halt 401 unless session[:usuario]
  Empleado.borrar(id: params[:id], id_usuario: session[:usuario_id], ip: request.ip)
  headers 'HX-Trigger' => 'empleadosActualizado'
  msg_ok('Empleado eliminado.')
end

post '/api/empleados/:id/intento-borrado' do
  halt 401 unless session[:usuario]
  Empleado.registrar_intento_borrado(id: params[:id], id_usuario: session[:usuario_id], ip: request.ip)
  ''
end