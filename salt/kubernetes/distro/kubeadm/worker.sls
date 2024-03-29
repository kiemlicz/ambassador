#load modules ip_vs, ip_vs_rr, ip_vs_wrr, ip_vs_sh, nf_conntrack_ipv4
{%- set masters = kubernetes.nodes.masters %}
{%- set main_master_id = kubernetes.nodes.masters|first %}
{%- set tokens = salt['mine.get'](masters|join(","), "kubernetes_token", tgt_type="list") %}
{%- set ips = salt['mine.get'](masters|join(","), "kubernetes_master_ip", tgt_type="list") %}
{%- set hashes = salt['mine.get'](masters|join(","), "kubernetes_hash", tgt_type="list") -%}


include:
    - kubernetes.distro.kubeadm

{%- if ips and tokens and hashes %}
{%- if kubernetes.worker.reset %}
kubeadm_worker_reset:
  cmd.run:
    - name: "echo y | kubeadm reset"
    - require:
        - pkg: kubeadm
    - require_in:
        - cmd: join_master
{%- endif %}
join_master: # fixme from 3001 there is a module for this
    cmd.run:
        - name: "kubeadm join {{ ips[main_master_id][0] }}:{{ kubernetes_network.nodes.apiserver_port }} --token {{ tokens[main_master_id]|selectattr('usages', 'match', '.*authentication.*')|map(attribute="token")|first }} --discovery-token-ca-cert-hash sha256:{{ hashes[main_master_id] }}"
        - require:
            - pkg: kubeadm
{%- else %}
kubernetes-no-masters-to-join:
    test.fail_without_changes:
        - name: Kubernetes worker node found no master with hash and token active
{%- endif %}
