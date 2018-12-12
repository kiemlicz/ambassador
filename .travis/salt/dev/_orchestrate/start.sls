refresh_pillar:
    salt.function:
        - name: saltutil.refresh_pillar
        - tgt: '*'

# every minion corresponds to k8s node
# wait for all minion, then publish event to start deployment

salt_minion_started:
  salt.runner:
    - name: event_ext.send_when
    - tag: 'salt/orchestrate/k8s/ready'
    - condition: __slot__:salt:condition.pillar_eq("salt:kubernetes:status:numberAvailable", "salt:kubernetes:status:numberReady")
    - data: {}
    - require:
        - salt: refresh_pillar
