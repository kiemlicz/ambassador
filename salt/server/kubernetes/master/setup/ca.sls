{%- from "kubernetes/master/map.jinja" import kubernetes with context %}

kubernetes_pki_dir:
  file.directory:
  - name: {{ kubernetes.master.pki.dir }}
  - makedirs: True
  - user: {{ kubernetes.master.pki.user|default("root") }}
  - group: {{ kubernetes.master.pki.group|default("root") }}

kubernetes_ca_key:
  x509.private_key_managed:                                     
  - name: "{{ kubernetes.master.pki.dir }}/{{ kubernetes.master.ca.priv }}"
  - bits: {{ kubernetes.master.ca.priv_keylen|default(4096) }}                                                
  - backup: True                                              
  - require:                                                  
    - file: kubernetes_pki_dir

kubernetes_ca_cert:
  x509.certificate_managed:
  - name: "{{ kubernetes.master.pki.dir }}/{{ kubernetes.master.ca.pub }}"
  - signing_private_key: "{{ kubernetes.master.pki.dir }}/{{ kubernetes.master.ca.priv }}"
  - CN: {{ kubernetes.master.ca.cn }}
  - backup: True
  - basicConstraints: "critical CA:true"
  - keyUsage: "critical digitalSignature, keyEncipherment, keyCertSign"
  - days_valid: {{ kubernetes.master.ca.days_valid }}
  - require:
      - x509: kubernetes_ca_key
