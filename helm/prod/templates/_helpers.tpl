{{- define "local-infra-prod.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "local-infra-prod.fullname" -}}
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

{{- define "local-infra-prod.labels" -}}
helm.sh/chart: {{ include "local-infra-prod.name" . }}-{{ .Chart.Version | replace "+" "_" }}
{{ include "local-infra-prod.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "local-infra-prod.selectorLabels" -}}
app.kubernetes.io/name: {{ include "local-infra-prod.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}