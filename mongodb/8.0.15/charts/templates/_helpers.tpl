{{/* vim: set filetype=mustache: */}}

{{/*
Return the proper MongoDB image name
*/}}
{{- define "mongodb.image" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper metrics image name, including registry and digest overrides.
*/}}
{{- define "mongodb.metrics.image" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.metrics.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper agent image name
*/}}
{{- define "mongodb.agent.image" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.agent.image "global" .Values.global) }}
{{- end -}}
