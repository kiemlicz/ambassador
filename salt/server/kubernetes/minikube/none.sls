{% from "kubernetes/minikube/map.jinja" import kubernetes with context %}


{% for location in kubernetes.config.locations|reject("equalto", "/etc/kubernetes/admin.conf") %}
ensure_exists_{{ location }}:
  file.managed:
    - name: {{ location }}
    - makedirs: True
    - replace: False
    - user: {{ kubernetes.user }}
    - group: {{ kubernetes.group|default(kubernetes.user) }}
    - require_ in:
      - cmd: minikube_driver
    - require:
      - file: minikube
{% endfor %}

minikube_driver:
  cmd.run:
  - name: "minikube start --vm-driver=none"
{% if kubernetes.user != 'root' %}
  - env:
    - SUDO_USER: {{ kubernetes.user }}
    - HOME: {{ kubernetes.user_home|default("/home/" ~ kubernetes.user) }}
    - CHANGE_MINIKUBE_NONE_USER: true
    - MINIKUBE_HOME: {{ kubernetes.user_home|default(salt['user.info'](kubernetes.user).home) }}
    - KUBECONFIG: {{ kubernetes.config.locations|join(':') }}
{% endif %}
  - require:
    - file: minikube

minikube_permissions:
  file.directory:
    - names:
      - "{{ kubernetes.user_home|default(salt['user.info'](kubernetes.user).home) }}/.minikube"
      - "{{ kubernetes.user_home|default(salt['user.info'](kubernetes.user).home) }}/.kube"
    - user: {{ kubernetes.user }}
    - group: {{ kubernetes.group|default(kubernetes.user) }}
    - recurse:
      - user
      - group
    - require:
      - cmd: minikube_driver
