{% if data['fun'] == 'state.highstate' %}

detect_finish:
  runner.travis_stop.no_jobs_running:
    - args:
      - minion: {{ data['id'] }}

{% endif %}
