{%- for username, user in salt['pillar.get']("users", {}).items() %}

verify_user_{{ username }}:
  module_and_function: user.info
  args:
    - {{ username }}
  assertion: assertEqual
  expected_return: /bin/zsh
  assertion_section: shell
{%- endfor %}
