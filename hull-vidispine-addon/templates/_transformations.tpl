---
{{- define "hull.vidispine.addon.transformation" -}}
{{- $parent := (index . "PARENT_CONTEXT") -}}
{{- $source := (index . "SOURCE") -}}
{{- $caller := default nil (index . "CALLER") -}}
{{- $callerKey := default nil (index . "CALLER_KEY") -}}
{{- $shortForms := dict -}}
{{- $shortForms = set $shortForms "_HT?" (list "hull.util.transformation.bool" "CONDITION") -}}
{{- $shortForms = set $shortForms "_HT*" (list "hull.util.transformation.get" "REFERENCE") -}}
{{- $shortForms = set $shortForms "_HT!" (list "hull.util.transformation.tpl" "CONTENT") -}}
{{- $shortForms = set $shortForms "_HT^" (list "hull.util.transformation.makefullname" "COMPONENT") -}}
{{- if typeIs "map[string]interface {}" $source -}}
    {{- range $key,$value := $source -}}
        {{- if typeIs "map[string]interface {}" $value -}}
            {{- $params := default nil $value._HULL_TRANSFORMATION_ -}}
            {{- range $sfKey, $sfValue := $shortForms -}}
                {{- if (hasKey $value $sfKey) -}}
                    {{- $params = dict "NAME" (first $sfValue) (last $sfValue) (first (values (index $value $sfKey))) -}}
                {{- end -}} 
            {{- end -}} 
            {{- if $params -}} 
                {{- $pass := merge (dict "PARENT_CONTEXT" $parent "KEY" $key) $params -}}
                {{- $valDict := fromYaml (include $value._HULL_TRANSFORMATION_.NAME $pass) -}}
                {{- $source := unset $source $key -}}
                {{- $source := merge $source $valDict -}}  
            {{- else -}}
                {{- include "hull.vidispine.addon.transformation" (dict "PARENT_CONTEXT" $parent "SOURCE" $value "CALLER" $source "CALLER_KEY" $key) -}}
            {{- end -}}
        {{- end -}}
        {{- if typeIs "[]interface {}" $value -}}
            {{- include "hull.vidispine.addon.transformation" (dict "PARENT_CONTEXT" $parent "SOURCE" $value "CALLER" $source "CALLER_KEY" $key) -}}
        {{- end -}}
        {{- if typeIs "string" $value -}}
            {{- $params := default nil nil -}}
            {{- if (or (hasPrefix "_HULL_TRANSFORMATION_" $value) (hasPrefix "_HT?" $value) (hasPrefix "_HT*" $value) (hasPrefix "_HT!" $value) (hasPrefix "_HT^" $value)) -}}
                {{- range $sfKey, $sfValue := $shortForms -}}
                    {{- if (hasPrefix $sfKey $value) -}}
                        {{- $params = dict "NAME" (first $sfValue) (last $sfValue) (trimPrefix $sfKey $value) -}}
                    {{- end -}} 
                {{- end -}} 
                {{- if (hasPrefix "_HULL_TRANSFORMATION_" $value) -}}
                    {{- $paramsString := trimPrefix "_HULL_TRANSFORMATION_" $value -}}
                    {{- $paramsSplitted := regexFindAll "(<<<[A-Z]+=.+?>>>)" $paramsString -1 -}}
                    {{- $params = dict -}}
                    {{- range $p := $paramsSplitted -}}
                        {{- $params = set $params (trimPrefix "<<<" (first (regexSplit "=" $p -1))) (trimSuffix ">>>" (trimPrefix (printf "%s=" (first (regexSplit "=" $p -1))) $p)) -}}
                    {{- end -}}
                {{- end -}}
            {{- end -}}             
            {{- if $params }}
                {{- $pass := merge (dict "PARENT_CONTEXT" $parent "KEY" $key) $params -}}
                {{- $valDict := fromYaml (include ($params.NAME) $pass) -}} 
                {{- $source := unset $source $key -}}
                {{- $source := set $source $key (index $valDict $key) -}}  
            {{- end -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- if typeIs "[]interface {}" $source -}}
    {{- range $listentry := $source -}}
        {{- $newlistentry := include "hull.vidispine.addon.transformation" (dict "PARENT_CONTEXT" $parent "SOURCE" $listentry "CALLER" nil "CALLER_KEY" nil) -}}     
    {{- end -}}
    {{- $t2 := set $caller $callerKey $source -}}
{{- end -}}
{{- end -}}



{{- define "hull.vidispine.addon.producturis" -}}
{{- $parent := (index . "PARENT_CONTEXT") -}}
{{- $key := (index . "KEY") -}}
{{- $appends := (index . "APPENDS") -}}
{{- $c := list -}}
{{- $field := "" }}
{{- if (hasKey (index $parent.Values "hull").config.general.data.installation.config "productUris") -}}
{{- $field = "productUris" -}}
{{- end -}}
{{- if (ne $field "") -}}
{{- $uris := list -}}
{{ $key }}:
{{- range $u := (index ((index $parent.Values "hull").config.general.data.installation.config) $field) }}
{{- range $a := $appends }}
{{- $entry := printf "%s%s" $u $a }}
{{- if (has $entry $uris) -}}
{{- else -}}
{{- $uris = append $uris $entry }}
- {{ $entry }}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}



{{- define "hull.vidispine.addon.coruris" -}}
{{- $parent := (index . "PARENT_CONTEXT") -}}
{{- $key := (index . "KEY") -}}
{{- $c := list -}}
{{- $field := "" }}
{{- if (hasKey (index $parent.Values "hull").config.general.data.installation.config "productUris") -}}
{{- $field = "productUris" -}}
{{- end -}}
{{- if (ne $field "") -}}
{{- $origins := list -}}
{{ $key }}:
{{- range (index ((index $parent.Values "hull").config.general.data.installation.config) $field) }}
{{- $entry := printf "%s://%s"  (index (. | urlParse) "scheme") (index (. | urlParse) "host") }}
{{- if (has $entry $origins) -}}
{{- else -}}
{{- $origins = append $origins $entry }}
- {{ $entry }}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}



{{- define "hull.vidispine.addon.generalendpoint" -}}
{{- $parent := (index . "PARENT_CONTEXT") -}}
{{- $key := (index . "KEY") -}}
{{- $name := (index . "ENTRY") -}}
{{- $endpoint := (index . "ENDPOINT") -}}
{{- $excludeSubpath := (index . "EXCLUDE_SUBPATH") }}
{{- if hasKey $parent.Values.hull.config.general.data "endpoints" }}
{{- if hasKey $parent.Values.hull.config.general.data.endpoints $name }}
{{- if hasKey (index $parent.Values.hull.config.general.data.endpoints $name) "uri" }}
{{- if hasKey (index (index $parent.Values.hull.config.general.data.endpoints $name) "uri") $endpoint}}
{{- $ep := (index (index $parent.Values.hull.config.general.data.endpoints $name).uri $endpoint) -}}
{{- if $ep -}}
{{ $key }}:{{ printf " %s" $ep }}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}



{{- define "hull.vidispine.addon.ingress_classname_default" -}}
{{- $parent := (index . "PARENT_CONTEXT") -}}
{{- $key := (index . "KEY") -}}
{{ $key }}: {{ printf "nginx-%s" ($parent.Release.Name | quote) }}
{{- end -}}



{{- define "hull.vidispine.addon.makefullname" -}}
{{- $key := (index . "KEY") -}}
{{ $key }}: {{ template "hull.transformation.fullname" . }}
{{- end -}}



{{- define "hull.vidispine.addon.imagepullsecrets" -}}
{{- $key := (index . "KEY") -}}
{{ $key }}: 
  {{ template "hull.object.pod.imagePullSecrets" (dict "PARENT_CONTEXT" (index . "PARENT") "SPEC" (index . "SPEC") "HULL_ROOT_KEY" "hull") }}
{{- end -}}



{{- define "hull.vidispine.addon.producticon" -}}
{{- $parent := (index . "PARENT_CONTEXT") -}}
{{- $key := (index . "KEY") -}}
{{- $iconFile := (index . "ICON_FILE") -}}
Icon: |-
{{ $parent.Files.Get (printf "%s" $iconFile) | indent 2}}
{{- end -}}



{{ define "hull.vidispine.addon.sources.folder.volumes" }}
{{ $parent := (index . "PARENT_CONTEXT") }}
{
  "installation":
  { 
    "secret":{ "secretName": "hull-install" }
  },
  "custom-installation-files":
  {
    "secret": { "secretName": "custom-installation-files" }
  },
  "etcssl":
  {
    "enabled": {{ if $parent.Values.hull.config.general.data.installation.config.customCaCertificates }}true{{ else }}false{{ end }},
    "emptyDir": { }
  },
  "certs":
  {  "enabled": {{ if $parent.Values.hull.config.general.data.installation.config.customCaCertificates }}true{{ else }}false{{ end }},
     "secret": { "secretName": "custom-ca-certificates" }
  },
  {{ $processedDict := dict }}
  {{ $folderCount := 0 }}
  {{ range $file, $_ := $parent.Files.Glob "files/hull-vidispine-addon/installation/sources/**/*" }}
  {{- $folder := base (dir $file) }}
  {{- if not (hasKey $processedDict $folder) -}}
  {{ $folderCount = add $folderCount 1 }}
  {{ $_ := set $processedDict $folder "true" }}
  "custom-installation-files-{{ $folder }}":  
  {
      secret: 
      {
        secretName: "custom-installation-files-{{ $folderCount }}"
      }
  },
  {{ end }}
  {{ end }}
}
{{ end }}



{{ define "hull.vidispine.addon.sources.folder.volumemounts" }}
{{ $parent := (index . "PARENT_CONTEXT") }}
{
  "installation": 
  {
    "name": "installation",
    "mountPath": "/script"
  },
  "custom-installation-files":
  {
    "name": "custom-installation-files",
    "mountPath": "/custom-installation-files"
  },
  "etcssl": 
  {
    "enabled": {{ if $parent.Values.hull.config.general.data.installation.config.customCaCertificates }}true{{ else }}false{{ end }},
    "name": "etcssl",
    "mountPath": "/etc/ssl/certs"
  },
  {{ range $certkey, $certvalue := $parent.Values.hull.config.general.data.installation.config.customCaCertificates}}
  "custom-ca-certificates-{{ $certkey }}": 
  {
    "enabled": true, 
    "name": "certs",
    "mountPath": "/usr/local/share/ca-certificates/custom-ca-certificates-{{ $certkey }}",
    "subPath": "{{ $certkey }}"
  },
  {{ end }}
  {{ $processedDict := dict }}
  {{ range $file, $_ := $parent.Files.Glob "files/hull-vidispine-addon/installation/sources/**/*" }}
  {{- $folder := base (dir $file) }}
  {{- if not (hasKey $processedDict $folder) -}}
  {{ $_ := set $processedDict $folder "true" }}
  "custom-installation-files-{{ $folder }}":
  {
      "enabled": true, 
      "name": "custom-installation-files-{{ $folder }}",
      "mountPath": "/custom-installation-files-{{ $folder }}"
  },
  {{ end }}
  {{ end }}
}
{{ end }}



{{ define "hull.vidispine.addon.sources.folder.secret" }}
{{ $parent := (index . "PARENT_CONTEXT") }}
{{ $folderIndex := (index . "FOLDER_INDEX") }}
{
  {{ $processedDict := dict }}
  {{ $folderCount := 0 }}
  {{ range $file, $_ := $parent.Files.Glob "files/hull-vidispine-addon/installation/sources/**/*" }}
  {{- $folder := base (dir $file) }}
  {{- $fileName := base $file }}
  {{- if not (hasKey $processedDict $folder) -}}
  {{- $folderCount = add $folderCount 1 }}
  {{ $_ := set $processedDict $folder $folderCount }}
  {{- end -}}
  {{ if (eq (index $processedDict $folder) $folderIndex) }}
  {{ $fileName | base | quote }}: { path: {{ $file | quote }} },
  {{ end }}
  {{ end }}
}
{{ end }}



{{- define "hull.vidispine.addon.sources.folder.secret.count" -}}
{{- $parent := (index . "PARENT_CONTEXT") -}}
{{- $folderIndex := (index . "FOLDER_INDEX") -}}
{{- $processedDict := dict -}}
{{- $folderCount := 0 -}}
{{- $folderExists := false -}}
{{- range $file, $_ := $parent.Files.Glob "files/hull-vidispine-addon/installation/sources/**/*" -}}
{{- $folder := base (dir $file) -}}
{{- if not (hasKey $processedDict $folder) -}}
{{- $folderCount = add $folderCount 1 -}}
{{- $_ := set $processedDict $folder $folderCount -}}
{{- end -}}
{{- end -}}
{{- $folderCount -}}
{{- end -}}