FROM mcr.microsoft.com/mssql/server:2022-latest

USER root

RUN apt-get update && apt-get install -y dos2unix && rm -rf /var/lib/apt/lists/*

WORKDIR /db-init

COPY schema.sql       ./schema.sql
COPY stored_procedures/sp_carga_xml.sql ./sp_carga_xml.sql
COPY entrypoint.sh    ./entrypoint.sh

RUN dos2unix entrypoint.sh schema.sql sp_carga_xml.sql && chmod +x entrypoint.sh

USER mssql

ENTRYPOINT ["/db-init/entrypoint.sh"]
