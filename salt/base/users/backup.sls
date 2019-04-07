{% for username, user in salt['pillar.get']("users", {}).items() if user.backup is defined %}

{{ username }}_backup:
  file_ext.managed:
    - name: {{ user.backup.script_location }}
    - source: salt://users/backup.sh
    - user: {{ username }}
    - template: jinja
    - makedirs: True
    - mode: 775
    - context:
{% if user.backup.remote is defined %}
        remote: {{ user.backup.remote }}
{% endif %}
        locations: {{ user.backup.source_locations|join(' ') }}
        destination: {{ user.backup.destination_location }}
        archive: {{ user.backup.archive_location }}
    - require:
      - user: {{ username }}
  cron.present:
    - name: {{ user.backup.script_location }}
    - user: {{ username }}
    - hour: {{ user.backup.hour }}
    - minute: {{ user.backup.minute }}
{% if user.backup.daymonth is defined %}
    - daymonth: {{ user.backup.daymonth }}
{% endif %}
{% if user.backup.month is defined %}
    - month: {{ user.backup.month }}
{% endif %}
{% if user.backup.dayweek is defined %}
    - dayweek: {{ user.backup.dayweek }}
{% endif %}
    - require:
      - file_ext: {{ user.backup.script_location }}

{% endfor %}
