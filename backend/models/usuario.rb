require_relative '../config/database'

class Usuario
  def self.login(username:, password:, ip:)
    Database.query do |db|
      sql = "DECLARE @Codigo INT; " \
            "EXEC dbo.sp_login " \
            "  @Username = N'#{username.gsub("'","''")}', " \
            "  @Password = N'#{password.gsub("'","''")}', " \
            "  @IP       = N'#{ip}', " \
            "  @Codigo   = @Codigo OUTPUT; " \
            "SELECT @Codigo AS Codigo;"

      # Aqui el StoreProcedure deberia de devolver el SELECT de usuarios y un output
      # Entonces es nada mas iterar hasta que se encuentre el que tiene codigo
      result = db.execute(sql)
      codigo    = nil
      usuario   = nil

      result.each(as: :hash) do |fila|
        if fila.key?('Codigo')
          codigo = fila['Codigo'].to_i
        elsif fila.key?('Id')
          usuario = fila
        end
      end

      { codigo: codigo, usuario: usuario }
    end
  end

  def self.logout(id_usuario:, ip:)
    Database.query do |db|
      db.execute(
        "EXEC dbo.sp_logout @IdUsuario = #{id_usuario.to_i}, @IP = N'#{ip}'"
      ).do
    end
  end
end