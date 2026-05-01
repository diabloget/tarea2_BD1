require_relative '../models/usuario'
 
post '/login' do
  username = params[:username].to_s.strip
  password = params[:password].to_s.strip
  ip       = request.ip
 
  resultado = Usuario.login(username: username, password: password, ip: ip)
  codigo    = resultado[:codigo]
  usuario   = resultado[:usuario]
 
  if codigo == 0 && usuario
    session[:usuario]    = usuario['Username']
    session[:usuario_id] = usuario['Id']
    redirect '/'
  elsif codigo == 50003
    @error = 'Demasiados intentos. Intentá de nuevo en 10 minutos.'
    redirect '/login'
  else
    @error = codigo == 50001 ? 'Usuario no existe.' : 'Contraseña incorrecta.'
    redirect '/login'
  end
end
 
post '/logout' do
  if session[:usuario_id]
    Usuario.logout(id_usuario: session[:usuario_id], ip: request.ip)
  end
  session.clear
  redirect '/login'
end
