{% from "os/repositories/map.jinja" import repositories with context %}
{% from "_common/repo.jinja" import repository, preferences with context %}

{% for repo in repositories.list %}
# refresh on last configured repo
{{ repository(repo.file ~ "_" ~ repo.names|first ~ "_repository", repo, refresh=(repositories.list|last == repo)) }}
{% endfor %}

{% for pref in repositories.preferences %}
{{ preferences(pref.file ~ "_repository", pref, repositories.preferences_source, pref.file) }}
{% endfor %}

repositories-notification:
  test.show_notification:
    - name: Repositories setup completed
    - text: "Repositories setup completed"
