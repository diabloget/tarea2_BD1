require_relative '../models/empleado'
require_relative '../models/puesto'

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
    saldo = '%.2f' % e['SaldoVacaciones'].to_f
    "<tr>
      <td>#{e['ValorDocumentoIdentidad']}</td>
      <td>#{e['Nombre']}</td>
      <td>#{e['Puesto']}</td>
      <td>#{saldo}</td>
      <td class='td-acciones'>
        <button class='btn-accion'>Ver</button>
        <button class='btn-accion'>Editar</button>
        <button class='btn-accion'>Borrar</button>
      </td>
    </tr>"
  end.join
end

get '/api/puestos' do
  halt 401 unless session[:usuario]
  puestos = Puesto.todos
  puestos.map { |p| "<option value='#{p['Id']}'>#{p['Nombre']}</option>" }.join
end

post '/api/empleados' do
  halt 401 unless session[:usuario]

  cedula   = params[:cedula].to_s.strip
  nombre   = params[:nombre].to_s.strip
  id_puesto = params[:id_puesto].to_s.strip
  fecha    = params[:fecha_contratacion].to_s.strip

  if cedula.empty? || nombre.empty? || id_puesto.empty? || fecha.empty?
    return "<span style='color:#9b3a3a'>Todos los campos son requeridos.</span>"
  end

  unless cedula.match?(/\A\d+\z/)
    return "<span style='color:#9b3a3a'>La cédula debe ser numérica.</span>"
  end

  unless nombre.match?(/\A[A-Za-záéíóúÁÉÍÓÚñÑüÜ\s\-]+\z/)
    return "<span style='color:#9b3a3a'>El nombre debe ser alfabético.</span>"
  end

  codigo = Empleado.crear(
    cedula:             cedula,
    nombre:             nombre,
    id_puesto:          id_puesto,
    fecha_contratacion: fecha,
    id_usuario:         session[:usuario_id],
    ip:                 request.ip
  )

  if codigo == 0
    headers 'HX-Trigger' => 'empleadosActualizado'
    "<span style='color:#2d5a4e'>Empleado insertado correctamente.</span>"
  elsif codigo == 50004
    "<span style='color:#9b3a3a'>Ya existe un empleado con esa cédula.</span>"
  elsif codigo == 50005
    "<span style='color:#9b3a3a'>Ya existe un empleado con ese nombre.</span>"
  else
    "<span style='color:#9b3a3a'>Error inesperado (código #{codigo}).</span>"
  end
end