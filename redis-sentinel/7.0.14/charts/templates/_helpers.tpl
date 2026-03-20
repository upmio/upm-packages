{{/* vim: set filetype=mustache: */}}

{{/*
Return the proper MySQL image name
*/}}
{{- define "redis-sentinel.image" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper metrics image name
*/}}
{{- define "redis-sentinel.metrics.image" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.metrics.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper agent image name
*/}}
{{- define "redis-sentinel.agent.image" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.agent.image "global" .Values.global) }}
{{- end -}}
