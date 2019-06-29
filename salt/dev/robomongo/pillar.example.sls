{% set owner = 'testuser' %}
{% set home_dir = '/home/' + owner %}
robomongo:
  owner: {{ owner }}
  owner_link_location: {{ home_dir }}/bin/robomongo
