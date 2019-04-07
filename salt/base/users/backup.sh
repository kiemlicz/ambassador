#!/usr/bin/env bash

{% if remote is defined %}
#rsync
rsync -rv --delete -e ssh {{ locations }} {{ remote }}:{{ destination }}
#archive
name={{ archive }}.$(date +%Y%m%d.%H%M.tgz)
archive_cmd="tar cvfz $name -C {{ destination }} ."
ssh {{ remote }} "$archive_cmd"
{% else %}
#rsync
rsync -rv --delete {{ locations }} {{ destination }}
#archive
name={{ archive }}.$(date +%Y%m%d.%H%M.tgz)
tar cvfz $name -C {{ destination }} .
{% endif %}
