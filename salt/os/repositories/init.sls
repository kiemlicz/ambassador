{% from "os/repositories/map.jinja" import repositories with context %}
{% from "_common/repo.jinja" import repository, preferences with context %}

{% if repositories.list | length > 0 %}
{{ repositories.sources_list_location }}_clean:
  file.absent:
    - name: {{ repositories.sources_list_location }}
{% endif %}
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
