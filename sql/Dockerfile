FROM mcr.microsoft.com/mssql/server:2022-latest

USER root

RUN apt-get update && apt-get install -y dos2unix && rm -rf /var/lib/apt/lists/*

WORKDIR /db-init

COPY schema.sql                  ./schema.sql
COPY sp_carga_xml.sql            ./sp_carga_xml.sql
COPY sp_login.sql                ./sp_login.sql
COPY sp_logout.sql               ./sp_logout.sql
COPY sp_listar_empleados.sql     ./sp_listar_empleados.sql
COPY entrypoint.sh               ./entrypoint.sh

RUN dos2unix entrypoint.sh schema.sql sp_carga_xml.sql \
    sp_login.sql sp_logout.sql sp_listar_empleados.sql \
    && chmod +x entrypoint.sh \
    && chmod 644 schema.sql sp_carga_xml.sql sp_login.sql sp_logout.sql sp_listar_empleados.sql

USER mssql

ENTRYPOINT ["/db-init/entrypoint.sh"]