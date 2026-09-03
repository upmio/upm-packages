{{/* vim: set filetype=mustache: */}}

{{- define "hugegraph.image" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global) }}
{{- end -}}

{{- define "hugegraph.agent.image" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.agent.image "global" .Values.global) }}
{{- end -}}
