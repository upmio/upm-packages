{{/* vim: set filetype=mustache: */}}

{{/*
Return the proper ProxySQL image name
*/}}
{{- define "proxysql.image" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper agent image name
*/}}
{{- define "proxysql.agent.image" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.agent.image "global" .Values.global) }}
{{- end -}}
