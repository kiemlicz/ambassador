{% from "kubernetes/worker/map.jinja" import kubernetes with context %}
{% from "kubernetes/network/map.jinja" import kubernetes as kubernetes_network with context %}

#load modules ip_vs, ip_vs_rr, ip_vs_wrr, ip_vs_sh, nf_conntrack_ipv4

{% set masters = kubernetes.nodes.masters %}
{% set tokens = salt['mine.get'](masters|join(","), "kubernetes_token", tgt_type="list") %}
{% set ips = salt['mine.get'](masters|join(","), "kubernetes_master_ip", tgt_type="list") %}
{% set hashes = salt['mine.get'](masters|join(","), "kubernetes_hash", tgt_type="list") %}

{% if ips and tokens and hashes %}
{% if kubernetes.worker.reset %}
kubeadm_worker_reset:
  cmd.run:
    - name: "echo y | kubeadm reset"
    - require:
        - pkg: kubeadm
    - require_in:
        - cmd: join_master
{% endif %}
{% set main_master_id = ips.keys()|sort|first %}
join_master:
    cmd.run:
        - name: "kubeadm join --token {{ tokens[main_master_id]['stdout'] }} {{ ips[main_master_id][0] }}:{{ kubernetes_network.nodes.port }} --discovery-token-ca-cert-hash sha256:{{ hashes[main_master_id] }}"
        - require:
            - pkg: kubeadm
{% else %}
kubernetes-no-masters-to-join:
    test.fail_without_changes:
        - name: Kubernetes worker node found no master with hash and token active
{% endif %}