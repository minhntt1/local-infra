{{- define "mysql-exporter-prod.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "mysql-exporter-prod.fullname" -}}
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

{{- define "mysql-exporter-prod.labels" -}}
helm.sh/chart: {{ include "mysql-exporter-prod.name" . }}-{{ .Chart.Version | replace "+" "_" }}
{{ include "mysql-exporter-prod.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "mysql-exporter-prod.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mysql-exporter-prod.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
