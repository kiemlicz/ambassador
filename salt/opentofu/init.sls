{%- from "opentofu/map.jinja" import opentofu with context %}

include:
  - os

opentofu_key:
  file.managed:
    - name: /etc/apt/keyrings/opentofu.gpg
    - source: https://get.opentofu.org/opentofu.gpg
    - skip_verify: True
    - mode: 644
    - require:
        - sls: os

opentofu_repokey:
  cmd.run:
    - name: "curl -fsSL https://packages.opentofu.org/opentofu/tofu/gpgkey | sudo gpg --no-tty --batch --dearmor -o /etc/apt/keyrings/opentofu-repo.gpg >/dev/null"
    - creates: /etc/apt/keyrings/opentofu-repo.gpg
    - require:
        - sls: os
# mode 644?

opentofu_repo:
  file.managed:
    - name: {{opentofu.file}}
    - contents: |
        Types: deb deb-src
        URIs: https://packages.opentofu.org/opentofu/tofu/any/
        Suites: any
        Components: main
        Signed-By: /etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg
    - require:
        - file: opentofu_key
        - cmd: opentofu_repokey
  cmd.run:
    - name: "apt update"
    - require:
        - file: opentofu_repo
  pkg.latest:
    - name: tofu
    - require:
        - cmd: opentofu_repo
