{{/* vim: set filetype=mustache: */}}

{{/*
Return the proper ClickHouse Keeper image name.
*/}}
{{- define "clickhouse-keeper.image" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper unit-agent image name.
*/}}
{{- define "clickhouse-keeper.agent.image" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.agent.image "global" .Values.global) }}
{{- end -}}
