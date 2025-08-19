{{/* vim: set filetype=mustache: */}}

{{/*
Return the proper pgbouncer image name
*/}}
{{- define "pgbouncer.image" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper agent image name
*/}}
{{- define "pgbouncer.agent.image" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.agent.image "global" .Values.global) }}
{{- end -}}
