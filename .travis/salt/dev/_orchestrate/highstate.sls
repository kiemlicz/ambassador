# to be used for k8s counterpart of docker-compose
update_mine:
  salt.function:
  - name: mine.update
  - tgt: {{ pillar['event']['data']['id'] }}

highstate:
  salt.state:
  - tgt: {{ pillar['event']['data']['id'] }}
  - highstate: True
  - saltenv: {{ saltenv }}
  - pillarenv: {{ pillarenv }}
  - require:
    - salt: update_mine

