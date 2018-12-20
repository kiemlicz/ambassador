{% for test in '/opt/tests/' | list_files %}
    {% if test|is_text_file %}
run_{{ test }}:
  salt.runner:
  - name: salt.cmd
  - arg:
    - cmd.run
    - "python {{ test }}"
  - require_in:
    - salt: notify_test_success
  - onfail_in:
    - salt: notify_test_fail
    {% endif %}
{% endfor %}

notify_test_success:
  salt.runner:
    - name: event.send
    - tag: 'salt/orchestrate/redis/tests/success'

notify_test_fail:
  salt.runner:
    - name: event.send
    - tag: 'salt/orchestrate/redis/tests/fail'
