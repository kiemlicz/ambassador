{% from "vscode/map.jinja" import vscode with context %}
{% from "_macros/dev_tool.macros.jinja" import link_to_bin with context %}
{% from "_common/util.jinja" import retry with context %}


include:
  - users


vscode:
  devtool.managed:
    - name: {{ vscode.generic_link }}
    - download_url: {{ vscode.download_url }}
    - destination_dir: {{ vscode.destination_dir }}
    - user: {{ vscode.owner }}
    - group: {{ vscode.owner }}
    - saltenv: {{ saltenv }}
{{ retry(attempts=4, interval=30)| indent(4) }}
    - require:
      - sls: users
{{ link_to_bin(vscode.owner_link_location, vscode.generic_link + '/bin/idea.sh', vscode.owner) }}
