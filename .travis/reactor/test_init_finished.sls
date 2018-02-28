{% if data['fun'] == 'mine.update' and data['success'] and data['retcode'] == 0 %}

init_finished:
  runner.wait.until:
    - args:
      - expected_minions_list: {{ salt['pillar.get']("minions", pillarenv=salt['environ.get']("PILLARENV")) }}
      - triggering_minion: {{ data['id'] }}
      - action_type: "init"
      - fun_args: {{ data['fun_args'] }}

{% elif data['fun'] == 'mine.update' %}

failed:
  runner.event.send:
    - args:
      - tag: 'salt/init/failure'

{% endif %}
