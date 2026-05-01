require_relative '../models/empleado'

get '/api/empleados' do
  # Error de sesion
  unless session[:usuario]
    return '<tr><td colspan="5" style="text-align:center;color:#f87171;padding:1rem;">
      Sesión expirada. <a href="/login" style="color:#00d4ff">Inicia sesión</a>
    </td></tr>'
  end

  filtro    = params[:filtro].to_s.strip
  empleados = Empleado.todos(filtro: filtro.empty? ? nil : filtro)

  if empleados.empty?
    return '<tr class="empty-row"><td colspan="5" style="text-align:center;color:#666;padding:2rem;">
      Sin registros. Cargá el XML primero.
    </td></tr>'
  end

  empleados.map do |e|
    "<tr>
      <td>#{e['ValorDocumentoIdentidad']}</td>
      <td>#{e['Nombre']}</td>
      <td>#{e['Puesto']}</td>
      <td>#{e['SaldoVacaciones']}</td>
      <td class='acciones'>
        <button class='btn-accion'>Ver</button>
        <button class='btn-accion'>Editar</button>
        <button class='btn-accion'>Borrar</button>
      </td>
    </tr>"
  end.join
end