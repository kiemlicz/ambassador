#!py


import logging

log = logging.getLogger(__name__)


def run():
    ret = {
        'redis': {
            'setup_type': "cluster",
            'reset': False,
            'replication_factor': 2,
            'instances': {
                'map': {}
            }
        }}

    # todo think about dynamic ext pillar addition

    if not 'redis' in pillar or not 'kubernetes' in pillar['redis']:
        log.info("Kubernetes redis pillar data is not available")
        return ret

    if not 'pods' in pillar['redis']['kubernetes']:
        log.info("Pods data (kubectl get pods -o yaml)")
        return ret

    redis_pods = pillar['redis']['kubernetes']['pods']['items']
    for kubectl_pod in redis_pods:
        if not 'podIP' in kubectl_pod['status']:
            log.warn("Statefuset is not yet complete")
            return {}
        pod_name = kubectl_pod['metadata']['name']
        #todo flatmap
        pod_port_list = kubectl_pod['spec']['containers'][0]['ports']
        pod_port = [e['containerPort'] for e in pod_port_list if e['name'] == "redis-cluster"][0]
        pod_ip = kubectl_pod['status']['podIP']
        pod_ip_list = [pod_ip]

        ret['redis']['instances']['map'][pod_name] = {
            'ip': pod_ip,
            'ips': pod_ip_list,
            'port': pod_port,
            'ports': pod_port_list,
        }

    ret['redis']['instances']['size'] = len(redis_pods)

    return ret
