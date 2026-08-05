{{- define "liquibase-runner.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "liquibase-runner.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "liquibase-runner.labels" -}}
helm.sh/chart: {{ include "liquibase-runner.name" . }}-{{ .Chart.Version | replace "+" "_" }}
{{ include "liquibase-runner.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "liquibase-runner.selectorLabels" -}}
app.kubernetes.io/name: {{ include "liquibase-runner.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
