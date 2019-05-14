{% for username, user in salt['pillar.get']("users", {}).items() if user.cron is defined %}
{% for cron in user.cron %}

{{ username }}_setup_cron_{{ cron.name }}:
  cron.present:
    - name: {{ cron.name }}
    - user: {{ username }}
    - minute: {{ cron.minute|default('"*"') }}
    - hour: {{ cron.hour|default('"*"') }}
    - daymonth: {{ cron.daymonth|default('"*"') }}
    - month: {{ cron.month|default('"*"')}}
    - dayweek: {{ user.backup.dayweek|default('"*"') }}
    - require:
      - sls: users.common

{% endfor %}
{% endfor %}
