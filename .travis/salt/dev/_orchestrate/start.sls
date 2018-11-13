update_mine:
  salt.function:
  - name: mine.update
  - tgt: {{ pillar['tgt'] }}

highstate:
  salt.state:
  - tgt: {{ pillar['tgt'] }}
  - highstate: True
  - saltenv: {{ saltenv }}
  - pillarenv: {{ pillarenv }}
  - require:
    - salt: mine

