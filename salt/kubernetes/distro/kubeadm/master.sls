ensure_token:
  module.run:
    - kubeadm.token_create: []
    - unless:
      - fun: kubeadm.token_list
    - require:
      - cmd: kubeadm_init

propagate_token:
  module.run:
    - mine.send:
        - kubernetes_token
        - mine_function: kubeadm.token_list
    - require:
      - module: ensure_token

propagate_hash:
  module.run:
    - mine.send:
        - kubernetes_hash
        - mine_function: cmd.run
        - "openssl x509 -pubkey -in {{ kubernetes.master.pki.dir }}/{{ kubernetes.master.ca.pub }} | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'"
        - python_shell: True
    - require:
      - cmd: kubeadm_init
