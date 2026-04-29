require_relative '../models/empleado'

get '/api/empleados' do
  halt 401 unless session[:usuario]

  filtro    = params[:filtro].to_s.strip
  empleados = Empleado.todos(filtro: filtro.empty? ? nil : filtro)

  empleados.map do |e|
    "<tr>
      <td>#{e['ValorDocumentoIdentidad']}</td>
      <td>#{e['Nombre']}</td>
      <td>#{e['Puesto']}</td>
      <td>#{e['SaldoVacaciones']}</td>
      <td>
        <button onclick=\"alert('Consultar #{e['Nombre']}')\">Ver</button>
        <button onclick=\"alert('Editar #{e['Nombre']}')\">Editar</button>
        <button onclick=\"alert('Borrar #{e['Nombre']}')\">Borrar</button>
      </td>
    </tr>"
  end.join
end