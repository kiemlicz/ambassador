{%- from "cert/map.jinja" import cert with context %}

ca_cert:
  x509.certificate_managed:
  - name: {{ cert.ca }}
  - signing_private_key: {{ cert.ca_key }}
