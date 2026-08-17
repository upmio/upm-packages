{{/* vim: set filetype=mustache: */}}

{{/*
Return the proper ClickHouse image name.
*/}}
{{- define "clickhouse.image" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper ClickHouse agent image name.
*/}}
{{- define "clickhouse.agent.image" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.agent.image "global" .Values.global) }}
{{- end -}}
