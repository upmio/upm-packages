{{/* vim: set filetype=mustache: */}}

{{/*
Return the proper MySQL image name
*/}}
{{- define "redis.image" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper agent image name
*/}}
{{- define "redis.agent.image" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.agent.image "global" .Values.global) }}
{{- end -}}
