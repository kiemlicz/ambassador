{% set username = 'you_username' %}
{% set home_dir = '/home/' + username %}

users:
  {{ username }}:
    fullname: The full name
    nick: nickname
    home_dir: {{ home_dir }}
    shell: /bin/zsh
    groups:
      - sudo
      - wireshark
      - docker
      - vboxusers
    user_dirs:
      - {{ home_dir }}/bin
      - {{ home_dir }}/downloads
      - {{ home_dir }}/local
      - {{ home_dir }}/projects
      - {{ home_dir }}/share
      - {{ home_dir }}/.vpn
    known_hosts:
      - bitbucket.org
    sec:
      ssh_authorized_keys:
        - names:
          - "YfqjhSJK47ksdjhf7sdfa09sdV"
          - "YfqajhSsdsaJK47ksdjhf7sdfa09sdV"
          enc: "ssh-rsa"
        - source: salt://keys/user_key.pub
      ssh:
        - name: home
          privkey_location: {{ home_dir }}/.ssh/id_rsa
          pubkey_location: {{ home_dir }}/.ssh/id_rsa.pub
          override: False
        - name: dotfile
          privkey_location: {{ home_dir }}/.ssh/cfg_ro.key
          pubkey_location: {{ home_dir }}/.ssh/cfg_ro.key.pub
          override: False
    vpn:
    {% if grains['domain'] == 'somewhere' %}
      - name: nameofvpn
        location: {{ home_dir }}/.vpn/
        source: "salt://smome/VPN/"
    {% endif %}
    tools:
      oh_my_zsh:
        url: https://github.com/robbyrussell/oh-my-zsh.git
        target: {{ home_dir }}/projects/open-source/oh-my-zsh
      oh_my_zsh_syntax_highlighting:
        url: https://github.com/zsh-users/zsh-syntax-highlighting.git
        target: {{ home_dir }}/projects/open-source/oh-my-zsh/custom/plugins/zsh-syntax-highlighting
      fzf:
        url: https://github.com/junegunn/fzf.git
        target: {{ home_dir }}/projects/open-source/fzf
      powerline:
        pip: powerline-status
        required_pkgs:
          - python3-pip
          - vim-gtk3
          - fonts-powerline
    dotfile:
      repo: git@bitbucket.org:someuser/cfg.git
      branch: {{ grains['host'] }}
      root: {{ home_dir }}
      post_cmds:
        - "fc-cache -vf ~/.fonts"
    git:
      user.name: Someone
      user.email: someone@gmail.com
    projects:
      - url: https://github.com/kiemlicz/util.git
        target: {{ home_dir }}/projects/util
        cmds:
          - "ln -s {{ home_dir }}/projects/util {{ home_dir }}/projects/open-source/oh-my-zsh/custom/plugins/util"
      - url: https://github.com/VundleVim/Vundle.vim.git
        target: {{ home_dir }}/.vim/bundle/Vundle.vim
        cmds:
          - 'echo "\n" | vim +PluginInstall +qall'
    backup:
      script_location: {{ home_dir }}/bin/backup
      source_locations:
        - /etc
        - {{ home_dir }}/local
      destination_location: /mnt/Backup/OS/{{ grains['host'] }}
      remote: user@backup
      hour: 21
      minute: 0
      archive_location: /mnt/Archive/OS/{{ grains['host'] }}