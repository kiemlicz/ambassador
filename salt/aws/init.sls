{% from "aws/map.jinja" import aws with context %}
{% from "_common/util.jinja" import retry with context %}


include:
  - users


aws:
  archive.extracted:
    - name: {{ aws.destination_dir }}
    - source: {{ aws.download_url }}
    - user: {{ aws.owner }}
    - group: {{ aws.owner }}
    - skip_verify: True
{{ retry()| indent(4) }}
    - require:
      - sls: users
  cmd.run:
    - name: {{ aws.destination_dir }}/aws/install
    - creates: {{ aws.location }}
    - require:
      - archive: {{ aws.destination_dir }}
