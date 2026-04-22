#!/bin/bash
# Arranca SQL Server en segundo plano
/opt/mssql/bin/sqlservr &
SQL_PID=$!

echo "Esperando a que SQL Server esté listo..."
for i in {1..30}; do
  /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P "$MSSQL_SA_PASSWORD" \
    -C -Q "SELECT 1" > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "SQL Server listo. Ejecutando scripts de inicialización..."
    break
  fi
  echo "Intento $i/30, esperando 2s..."
  sleep 2
done

# Ejecutar schema solo si las tablas no existen todavía
/opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "$MSSQL_SA_PASSWORD" \
  -C -i /db-init/schema.sql
echo "schema.sql ejecutado."

# Ejecutar stored procedure (CREATE OR ALTER es idempotente)
/opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "$MSSQL_SA_PASSWORD" \
  -C -i /db-init/sp_carga_xml.sql
echo "sp_carga_xml.sql ejecutado."

echo "Base de datos lista."

# Mantener SQL Server en primer plano
wait $SQL_PID