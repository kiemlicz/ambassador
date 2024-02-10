{%- from "kubernetes/metallb/map.jinja" import kubernetes with context %}
{%- from "_common/util.jinja" import retry with context %}

include:
  - kubernetes.helm

# For BGP remember to setup BGP session on router
kubernetes_metallb_repo:
  helm.repo_managed:
    - present:
        - name: {{ kubernetes.metallb.helm.repo }}
          url: https://metallb.github.io/metallb

kubernetes_metallb_release:
  helm.release_present:
    - name: {{ kubernetes.metallb.helm.name }}
    - namespace: {{ kubernetes.metallb.helm.namespace }}
    - chart: {{kubernetes.metallb.helm.repo}}/{{kubernetes.metallb.helm.chart}}
    - version: {{ kubernetes.metallb.helm.version }}
    - set: {{ kubernetes.metallb.helm.set|tojson }}
    - flags:
      - "--create-namespace"
      - "--wait"
    - kvflags:
        kubeconfig: {{ kubernetes.config.locations|join(':') }}
    - require:
      - helm: kubernetes_metallb_repo
  cmd.run:
    - name: |
        cat <<EOF | kubectl apply -f -
        # common to L2 and BGP
        apiVersion: metallb.io/v1beta1
        kind: IPAddressPool
        metadata:
          name: {{ kubernetes.metallb.config.pool_name }}
          namespace: {{ kubernetes.metallb.helm.namespace }}
        spec:
          addresses: {{ kubernetes.metallb.config.addresses | tojson }}
{%- if 'bgp' in kubernetes.metallb.config %}
        ---
        apiVersion: metallb.io/v1beta2
        kind: BGPPeer
        metadata:
          name: {{ kubernetes.metallb.config.bgp.peer_name }}
          namespace: {{ kubernetes.metallb.helm.namespace }}
        spec:
          myASN: {{ kubernetes.metallb.config.bgp.my_asn }}
          peerASN: {{ kubernetes.metallb.config.bgp.peer_asn }}
          peerAddress: {{ kubernetes.metallb.config.bgp.peer_address }}
        ---
        apiVersion: metallb.io/v1beta1
        kind: BGPAdvertisement
        metadata:
          name: {{ kubernetes.metallb.config.bgp.peer_name }}-advertisement
          namespace: {{ kubernetes.metallb.helm.namespace }}
        spec:
            ipAddressPools:
                - {{ kubernetes.metallb.config.pool_name }}
{%- endif %}
        EOF
    - env:
        - KUBECONFIG: {{ kubernetes.config.locations|join(':') }}
    - require:
      - sls: kubernetes.helm
      - helm: kubernetes_metallb_release

# todo bgp update interval?
