{%- from "cert/map.jinja" import cert with context %}

ca_cert:
  x509.certificate_managed:
  - name: {{ cert.ca }}
  - signing_private_key: {{ cert.ca_key }}
  - CN: {{ cert.cn }}
  - backup: True
  - managed_private_key:
      name: {{ cert.ca_key }}
      bits: {{ cert.ca_keylen }}
      backup: True
