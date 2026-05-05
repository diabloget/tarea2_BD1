require_relative '../models/movimiento'
require_relative '../models/empleado'
require_relative '../models/error_catalogo'

get '/api/empleados/:id/movimientos' do
  halt 401 unless session[:usuario]

  e = Empleado.buscar(id: params[:id])
  halt 404 unless e

  movimientos = Movimiento.por_empleado(id_empleado: params[:id])
  saldo       = '%.2f' % e['SaldoVacaciones'].to_f

  filas = if movimientos.empty?
    '<tr><td colspan="7" style="text-align:center;color:#b5b3ae;padding:2rem;font-style:italic;">Sin movimientos registrados.</td></tr>'
  else
    movimientos.map do |m|
      signo = m['TipoAccion'] == 'Credito' ? '+' : '-'
      "<tr>
        <td>#{m['Fecha']}</td>
        <td>#{m['TipoMovimiento']}</td>
        <td>#{signo} #{'%.2f' % m['Monto'].to_f}</td>
        <td>#{'%.2f' % m['NuevoSaldo'].to_f}</td>
        <td>#{m['Usuario']}</td>
        <td>#{m['PostInIP']}</td>
        <td>#{m['PostTime']}</td>
      </tr>"
    end.join
  end

  "<div class='mov-header'>
    <div>
      <div class='mov-nombre'>#{e['Nombre']}</div>
      <div class='mov-meta'>#{e['ValorDocumentoIdentidad']} · #{e['Puesto']}</div>
    </div>
    <div class='mov-saldo'>Saldo: #{saldo}</div>
  </div>
  <div class='table-wrapper' style='margin-top:1rem'>
    <table>
      <thead>
        <tr>
          <th>Fecha</th><th>Tipo</th><th>Monto</th><th>Nuevo saldo</th>
          <th>Usuario</th><th>IP</th><th>Timestamp</th>
        </tr>
      </thead>
      <tbody>#{filas}</tbody>
    </table>
  </div>
  <div style='display:flex;justify-content:flex-end;margin-top:1rem'>
    <button class='btn-save' onclick='abrirInsertar(#{params[:id]})'>+ Agregar movimiento</button>
  </div>"
end

get '/api/tipos-movimiento' do
  halt 401 unless session[:usuario]
  Movimiento.tipos.map { |t| "<option value='#{t['Id']}'>#{t['Nombre']}</option>" }.join
end

post '/api/empleados/:id/movimientos' do
  halt 401 unless session[:usuario]

  id_tipo = params[:id_tipo].to_s.strip
  monto   = params[:monto].to_s.strip

  if id_tipo.empty? || monto.empty?
    return "<span style='color:#9b3a3a'>Todos los campos son requeridos.</span>"
  end
  unless monto.match?(/\A\d+(\.\d+)?\z/) && monto.to_f > 0
    return "<span style='color:#9b3a3a'>El monto debe ser un número positivo.</span>"
  end

  codigo = Movimiento.insertar(
    id_empleado: params[:id],
    id_tipo:     id_tipo,
    monto:       monto,
    id_usuario:  session[:usuario_id],
    ip:          request.ip
  )

  if codigo == 0
    headers 'HX-Trigger' => 'empleadosActualizado'
    "<span style='color:#2d5a4e'>Movimiento registrado correctamente.</span>"
  else
    "<span style='color:#9b3a3a'>#{ErrorCatalogo.descripcion(codigo)}</span>"
  end
end