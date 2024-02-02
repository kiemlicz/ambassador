{%- from "kubernetes/metallb/map.jinja" import kubernetes with context %}
{%- from "_common/util.jinja" import retry with context %}

include:
  - kubernetes.helm

# For BGP remember to setup BGP session on router
kubernetes_metallb:
  cmd.run:
    - name: |
        helm upgrade --install {{ kubernetes.metallb.release_name }} {{kubernetes.metallb.repo}}/{{kubernetes.metallb.chart}} -n {{ kubernetes.metallb.release_namespace }} --create-namespace \
        --version {{ kubernetes.metallb.version }} {{ kubernetes.metallb.options }} --wait
        cat <<EOF | kubectl apply -f -
        # common to L2 and BGP
        apiVersion: metallb.io/v1beta1
        kind: IPAddressPool
        metadata:
          name: {{ kubernetes.metallb.pool_name }}
          namespace: {{ kubernetes.metallb.release_namespace }}
        spec:
          addresses: {{ kubernetes.metallb.addresses | tojson }}
{%- if 'bgp' in kubernetes.metallb.config %}
        ---
        apiVersion: metallb.io/v1beta2
        kind: BGPPeer
        metadata:
          name: {{ kubernetes.metallb.config.bgp.peer_name }}
          namespace: {{ kubernetes.metallb.release_namespace }}
        spec:
          myASN: {{ kubernetes.metallb.config.bgp.my_asn }}
          peerASN: {{ kubernetes.metallb.config.bgp.peer_asn }}
          peerAddress: {{ kubernetes.metallb.config.bgp.peer_address }}
        ---
        apiVersion: metallb.io/v1beta1
        kind: BGPAdvertisement
        metadata:
          name: {{ kubernetes.metallb.config.bgp.peer_name }}-advertisement
          namespace: {{ kubernetes.metallb.release_namespace }}
        spec:
            ipAddressPools:
                - {{ kubernetes.metallb.pool_name }}
{%- endif %}
        EOF
    - env:
        - KUBECONFIG: {{ kubernetes.config.locations|join(':') }}
    - require:
      - sls: kubernetes.helm

# todo bgp update interval?
