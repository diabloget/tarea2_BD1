require_relative '../models/empleado'

get '/api/empleados' do
  # En rutas HTMX se devuelve HTML, no se hace un redirect
  unless session[:usuario]
    return '<tr><td colspan="5" style="text-align:center;color:#9b3a3a;padding:1rem;">
      Sesión expirada. <a href="/login" style="color:#2d5a4e">Ingresar</a>
    </td></tr>'
  end

  filtro    = params[:filtro].to_s.strip
  empleados = Empleado.todos(filtro: filtro.empty? ? nil : filtro)

  if empleados.empty?
    return '<tr class="empty-row"><td colspan="5">Sin registros.</td></tr>'
  end

  empleados.map do |e|
    # BigDecimal de TinyTDS da notación científica con .to_s — '%.2f' fuerza dos decimales
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