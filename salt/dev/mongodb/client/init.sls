{% from "mongodb/client/map.jinja" import mongodb_client as mongodb with context  %}


include:
  - os


mongodb_client:
  pkg.latest:
    - name: {{ mongodb.pkg_name }}
    - refresh: True
    - require:
      - sls: os
