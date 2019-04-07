{% from "minion/map.jinja" import minion with context %}

sync:
  module.run:
    - saltutil.sync_all:
        - refresh: True

mark:
  file.touch:
    - name: {{ minion.health_file }}
    - makedirs: True
    - require:
      - module: sync

inform:
  event.send:
    - name: {{ minion.event_tag }}
    - require:
      - file: mark
