{{/*
Expand the name of the chart.
*/}}
{{- define "chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "chart.fullname" -}}
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

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "chart.labels" -}}
helm.sh/chart: {{ include "chart.chart" . }}
{{ include "chart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "chart.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "chart.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Regex for a schema semantic version path segment (e.g. 1.2.3 or 1.2.3-beta.1).
*/}}
{{- define "chart.ingress.semverSegmentRegex" -}}
[\d]+\.[\d]+\.[\d]+(?:-[\w.-]+)?
{{- end }}

{{/*
Default API-like ingress path that excludes versioned prefixes.
Example: /api(?!/<semver>(?:/|$))(/|$)(.*)
Usage: include with dict {"root": $, "prefix": "api"}
*/}}
{{- define "chart.ingress.defaultPrefixedPathRegex" -}}
{{- $root := .root -}}
{{- $prefix := .prefix -}}
/{{ $prefix }}(?!/{{ include "chart.ingress.semverSegmentRegex" $root | trim }}(?:/|$))(/|$)(.*)
{{- end }}

{{/*
Default root ingress path that excludes reserved prefixes and versioned prefixes.
*/}}
{{- define "chart.ingress.defaultRootPathRegex" -}}
{{- $root := . -}}
/(?!api(?:/|$)|schema(?:/|$)|export(?:/|$)|sample(?:/|$)|{{ include "chart.ingress.semverSegmentRegex" $root | trim }}(?:/|$))(.*)
{{- end }}

{{/*
Build ingress annotations for rewrite-based ingresses.
Modes:
- community: ingress-nginx annotations only
- f5: F5 NGINX Ingress Controller annotations only
- both: emit both annotation families
User-provided ingress.annotations override chart defaults.
*/}}
{{- define "chart.ingress.annotations.rewrite" -}}
{{- $root := .root -}}
{{- $target := .target -}}
{{- $mode := default "both" $root.Values.ingress.annotationMode -}}
{{- $defaults := dict -}}
{{- if or (eq $mode "community") (eq $mode "both") -}}
{{- $_ := set $defaults "nginx.ingress.kubernetes.io/rewrite-target" $target -}}
{{- $_ := set $defaults "nginx.ingress.kubernetes.io/use-regex" "true" -}}
{{- end -}}
{{- if or (eq $mode "f5") (eq $mode "both") -}}
{{- $_ := set $defaults "nginx.org/path-regex" "case_sensitive" -}}
{{- $_ := set $defaults "nginx.org/rewrite-target" $target -}}
{{- end -}}
{{- toYaml (mergeOverwrite (dict) $defaults ($root.Values.ingress.annotations | default dict)) -}}
{{- end }}

{{/*
Build ingress annotations for doc ingress.
Only ingress-nginx needs an explicit use-regex=false default.
User-provided ingress.annotations override chart defaults.
*/}}
{{- define "chart.ingress.annotations.doc" -}}
{{- $root := . -}}
{{- $mode := default "both" $root.Values.ingress.annotationMode -}}
{{- $defaults := dict -}}
{{- if or (eq $mode "community") (eq $mode "both") -}}
{{- $_ := set $defaults "nginx.ingress.kubernetes.io/use-regex" "false" -}}
{{- end -}}
{{- toYaml (mergeOverwrite (dict) $defaults ($root.Values.ingress.annotations | default dict)) -}}
{{- end }}
