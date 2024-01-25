{% set owner = 'testuser' %}
{% set home_dir = '/home/' + owner %}
intellij:
  owner: {{ owner }}
  owner_link_location: {{ home_dir }}/bin/idea
