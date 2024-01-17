{{- define "openwifi.user_creation_script" -}}
{{- $root := . -}}
{{- $postgresqlBase := .Values.postgresql }}
{{- $postgresqlEmulatedRoot := (dict "Values" $postgresqlBase "Chart" (dict "Name" "postgresql") "Release" $.Release) }}
#!/bin/bash
export PGPASSWORD=postgres

echo "Testing if postgres is running before executing the initialization script."

until pg_isready -h postgresql -p 5432; do echo "Postgres is unavailable - sleeping"; sleep 2; done;

echo "Postgres is running, executing initialization script."

{{ range index .Values "pgsql" "initDbScriptSecret" "services" }}
echo "{{ . }}"
echo "SELECT 'CREATE USER {{ index $root "Values" . "configProperties" "storage.type.postgresql.username" }}' WHERE NOT EXISTS (SELECT FROM pg_user WHERE usename = '{{ index $root "Values" . "configProperties" "storage.type.postgresql.username" }}')\gexec" | psql -h {{ include "postgresql" $postgresqlEmulatedRoot }} postgres postgres
echo "ALTER USER {{ index $root "Values" . "configProperties" "storage.type.postgresql.username" }} WITH ENCRYPTED PASSWORD '{{ index $root "Values" . "configProperties" "storage.type.postgresql.password" }}'" | psql -h {{ include "postgresql" $postgresqlEmulatedRoot }} postgres postgres
echo "SELECT 'CREATE DATABASE {{ index $root "Values" . "configProperties" "storage.type.postgresql.database" }}' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '{{ index $root "Values" . "configProperties" "storage.type.postgresql.database" }}')\gexec" | psql -h {{ include "postgresql" $postgresqlEmulatedRoot }} postgres postgres
echo "GRANT ALL PRIVILEGES ON DATABASE {{ index $root "Values" . "configProperties" "storage.type.postgresql.database" }} TO {{ index $root "Values" . "configProperties" "storage.type.postgresql.username" }}" | psql -h {{ include "postgresql" $postgresqlEmulatedRoot }} postgres postgres
{{ end }}

echo "Postgres has been initialized."

{{- end -}}
