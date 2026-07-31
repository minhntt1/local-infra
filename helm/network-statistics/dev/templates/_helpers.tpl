{{- define "network-statistics-dev.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "network-statistics-dev.fullname" -}}
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

{{- define "network-statistics-dev.labels" -}}
helm.sh/chart: {{ include "network-statistics-dev.name" . }}-{{ .Chart.Version | replace "+" "_" }}
{{ include "network-statistics-dev.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "network-statistics-dev.selectorLabels" -}}
app.kubernetes.io/name: {{ include "network-statistics-dev.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "network-statistics-dev.imagePullSecret" -}}
{{- if .Values.imagePullSecret.enabled }}
{{- $auth := printf "%s:%s" .Values.imagePullSecret.username (.Values.imagePullSecret.password | b64dec) | b64enc }}
{{- $config := printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"auth\":\"%s\"}}}" .Values.imagePullSecret.registry .Values.imagePullSecret.username (.Values.imagePullSecret.password | b64dec) $auth }}
{{- $config | b64enc }}
{{- end }}
{{- end }}