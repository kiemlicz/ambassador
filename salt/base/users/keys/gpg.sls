{%- for username, user in salt['pillar.get']("users", {}).items() if user.sec is defined and user.sec %}
{%- if user.sec.gpg is defined %}
{%- for gpg, c in user.sec.gpg.items() %}
gpg_key_{{ username }}_{{ gpg }}:
  module.run:
    - gpg.import_key:
{%- if c.text is defined %}
        - text: {{ c.text }}
{%- else %}
        - filename: {{ c.filename }}
{%- endif %}
        - user: {{ username }}
{%- if c.gnupghome is defined %}
        - gnupghome: {{ c.gnupghome }}
    - require:
      - user: {{ username }}
{%- endif %}
{%- endfor %}
{%- endif %}
{%- endfor %}

gpg_keypairs_generation_completed:
  test.show_notification:
    - name: GPG Keypairs import completed
    - text: GPG Keypair already exists or was not specified
