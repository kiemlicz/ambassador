{% from "os/repositories/map.jinja" import repositories with context %}
{% from "_common/repo.jinja" import repository, preferences with context %}

{% for repo in repositories.list %}
# refresh on last configured repo
{{ repository(repo.file, repo, refresh=(repositories.list|last == repo)) }}
{% endfor %}

{% for pref in repositories.preferences %}
{{ preferences(pref.file ~ "_repository", pref, repositories.preferences_source, pref.file) }}
{% endfor %}

repositories-notification:
  test.succeed_without_changes:
    - name: Repositories setup completed
