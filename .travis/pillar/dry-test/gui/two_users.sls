{% set username = 'user1' %}
{% set username2 = 'user2' %}
{% set home_dir = '/home/' + username %}
{% set home_dir2 = '/home/' + username2 %}

users:
  {{ username }}:
    name: {{ username }}
    fullname: Coolest One
    nick: {{ username }}
    home_dir: {{ home_dir }}
    shell: /bin/zsh
    groups:
      - sudo
      - wireshark
      - docker
      - vboxusers
      - fancygroup
    user_dirs:
      - {{ home_dir }}/bin
      - {{ home_dir }}/downloads
      - {{ home_dir }}/projects
      - {{ home_dir }}/projects/open-source
      - {{ home_dir }}/share
      - {{ home_dir }}/.fancyhidden
    known_hosts:
      - bitbucket.org
      - github.com
    sec:
      ssh:
        home:
          privkey_location: {{ home_dir }}/.ssh/id_rsa
          pubkey_location: {{ home_dir }}/.ssh/id_rsa.pub
          override: True
        dotfile:
          privkey: |
            -----BEGIN RSA PRIVATE KEY-----
            MIIEpAIBAAKCAQEA14zSYevcHvxjiBqvZL5RwfMcDZ94l9f6aNvKhDqvFHpHII7M
            a8VH85J6ig9rMACaQ5869YQP/2M5IHN0oM1Fi29Up+viPwiB48h/xE3ymGvfPPXr
            fVF/MMAm7aFuCqr6VfwpGK5jQ8ksNgEySu/dbFdBAIRR2PVpK5mSMsqrOab0zes6
            ldofHXyZr0YT8tLvO/DafWSNp7LHiCyvoByv5mmRSZcLHhkiC4P22eFDYxHR+hZ9
            BmMUusdieNjx9TB1bVNXM29kQ+FCkwRakH6yvRg4exHBZ5jVnOJRWEZ2MNVKQFwY
            v5UXtZKYci6XnhyLrL1TyuvXkXIcUWW+4KlxywIDAQABAoIBAQC/aLDl/cGBzpRA
            J5o69vq5JT5zJnq7NDKM7SigVVBl+dOxqL0EsrKbLCce9GQ1w0M562s63GQsYJs5
            Iu2dYctw75MYbtKBMPfPI5u54ZIdIiWiB6tvpHAzBV9MQ77pQD1/H6YK4ckKR9m3
            t0ZG30wcSjtRzy6zX/Jdokj+S5TTYrriBKfVd+SBHXwyO/T1tbgo6ee2W+FeaJla
            wHjdaFOG0o5Z9KBrQHkvSmB96J5xrpg3qV/1367j/GHpalHX/nEC9iZbDsWPSecl
            113CPiy30xPQ0wyXq1gI60aA6ioxhmTNN5u+su0ciEwGWnCbofzdrmqpntmy9F3w
            ma5ank0pAoGBAO4c1rvS/KfRnZo3sPajvoFqyI6fmMRkuBjfTXky3nJjOSxPKNqR
            RQmtF9yxf23bjEWol1SWjrnjPI+DN0wT5P4mz6QF8/PSsViInMWTYNzZVLHh62sn
            uNFiRQC7p7Mo9Ci2zKZ6GNKaBNjcmenQ6VJNsoY8Ndb71ykXmUgELsA3AoGBAOe+
            FKiX/r5R+OtCkRxVdaTo7JMk7EFbmqknt84SwyXCDFu4huRXLRmCWYE52ppgbuze
            HLn8JmqeIbSEFBU9cfFR4EAYDyik0IBOep86AXjNGy7rtmAgTOXxE9lRiIDP06AG
            DgqF7PgpMDewDQ/+D1cpZ99TAwm4v1Z+rFXVVkkNAoGBAKHj/aNqCdnXzL2ji6/F
            GKtI/N7rZ6RvjjNq73OtwEwpZh/YGkCwcC3p/8VO8QKyOKbLv0gFrTh5ZR1160zQ
            YeriXF56pahq4aT+DQjP8RV2tfzTS4ppUWEa3StoataGy6o6zt2JOgNGMHF5WzP7
            lAcfSHe3zCtEwr7vionKPjb1AoGAMCk8udz8wCjhBmOLLMxF6sPNhrcBsoOLHOR4
            OoeDrvEpCFbNEd9cLBT+7PBNEhBAfVGbvrs8cKP0dUONuOxQJcrSQ/+8BsJZ4pBs
            w3KWo7hckd/Cwy9zS8ZSTbO4Hq0SWgtoF5/Fo71LnAcmb9Bo98BPKgZidz7B5QPm
            ZOA1UnECgYASO1p4Z8LdtVfOlJeegbd0E8CW40DBghbhsdT4v+whNfqM69iHI4XT
            K3sPevwBI7smMaaR0qtkyzmL0qmkWWki6Yf1wUXt+5wKOXds7RfjTqhf709LCkQT
            f9kW8Npa/9LipeWLwx5KpSh+UwNvUFBvP4B6vHZS9rUal5kv/U/EiQ==
            -----END RSA PRIVATE KEY-----
          pubkey: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDXjNJh69we/GOIGq9kvlHB8xwNn3iX1/po28qEOq8UekcgjsxrxUfzknqKD2swAJpDnzr1hA//Yzkgc3SgzUWLb1Sn6+I/CIHjyH/ETfKYa9889et9UX8wwCbtoW4KqvpV/CkYrmNDySw2ATJK791sV0EAhFHY9WkrmZIyyqs5pvTN6zqV2h8dfJmvRhPy0u878Np9ZI2nsseILK+gHK/maZFJlwseGSILg/bZ4UNjEdH6Fn0GYxS6x2J42PH1MHVtU1czb2RD4UKTBFqQfrK9GDh7EcFnmNWc4lFYRnYw1UpAXBi/lRe1kphyLpeeHIusvVPK69eRchxRZb7gqXHL coolnick@coolhost
          privkey_location: {{ home_dir }}/.ssh/cfg_ro.key
          pubkey_location: {{ home_dir }}/.ssh/cfg_ro.key.pub
          override: False
    vpn:
      - name: somename
        location: {{ home_dir }}/.vpn/
        config: |
          important
          vpn
          long
          data
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
          - vim-gtk3
          - python3-pip
    dotfile:
      repo: https://github.com/kiemlicz/ambassador.git
      branch: test-dotfiles
      root: {{ home_dir }}
      post_cmds:
        - "fc-cache -vf ~/.fonts"
    git:
      user.name: coolnick
      user.email: coolnick@gmail.com
    projects:
      - url: https://github.com/kiemlicz/util.git
        target: {{ home_dir }}/projects/util
        cmds:
          - "ln -s {{ home_dir }}/projects/util {{ home_dir }}/projects/open-source/oh-my-zsh/custom/plugins/util"
          - "ls -al {{ home_dir }}/projects/open-source/oh-my-zsh/custom/plugins/util"
      - url: https://github.com/VundleVim/Vundle.vim.git
        target: {{ home_dir }}/.vim/bundle/Vundle.vim
        cmds:
          - 'echo "\n" | vim +PluginInstall +qall'
    backup:
      script_location: {{ home_dir }}/bin/backup
      source_locations:
        - /etc
        - /boot
        - /var
        - /home
      destination_location: /some/backup/path/OS/{{ grains['host'] }}
      remote: coolguy@backuphost
      hour: 21
      minute: 0
      archive_location: /some/archive/path/OS/{{ grains['host'] }}
  {{ username2 }}:
    name: {{ username2 }}
    fullname: Coolest One
    nick: {{ username2 }}
    home_dir: {{ home_dir2 }}
    shell: /bin/zsh
    groups:
      - sudo
      - wireshark
      - docker
      - vboxusers
      - fancygroup
    user_dirs:
      - {{ home_dir2 }}/bin
      - {{ home_dir2 }}/downloads
      - {{ home_dir2 }}/projects
      - {{ home_dir2 }}/projects/open-source
      - {{ home_dir2 }}/share
      - {{ home_dir2 }}/.fancyhidden
    known_hosts:
      - bitbucket.org
      - github.com
    sec:
      ssh:
        home:
          privkey_location: {{ home_dir2 }}/.ssh/id_rsa
          pubkey_location: {{ home_dir2 }}/.ssh/id_rsa.pub
          override: True
        dotfile:
          privkey: |
            -----BEGIN RSA PRIVATE KEY-----
            MIIEpAIBAAKCAQEA14zSYevcHvxjiBqvZL5RwfMcDZ94l9f6aNvKhDqvFHpHII7M
            a8VH85J6ig9rMACaQ5869YQP/2M5IHN0oM1Fi29Up+viPwiB48h/xE3ymGvfPPXr
            fVF/MMAm7aFuCqr6VfwpGK5jQ8ksNgEySu/dbFdBAIRR2PVpK5mSMsqrOab0zes6
            ldofHXyZr0YT8tLvO/DafWSNp7LHiCyvoByv5mmRSZcLHhkiC4P22eFDYxHR+hZ9
            BmMUusdieNjx9TB1bVNXM29kQ+FCkwRakH6yvRg4exHBZ5jVnOJRWEZ2MNVKQFwY
            v5UXtZKYci6XnhyLrL1TyuvXkXIcUWW+4KlxywIDAQABAoIBAQC/aLDl/cGBzpRA
            J5o69vq5JT5zJnq7NDKM7SigVVBl+dOxqL0EsrKbLCce9GQ1w0M562s63GQsYJs5
            Iu2dYctw75MYbtKBMPfPI5u54ZIdIiWiB6tvpHAzBV9MQ77pQD1/H6YK4ckKR9m3
            t0ZG30wcSjtRzy6zX/Jdokj+S5TTYrriBKfVd+SBHXwyO/T1tbgo6ee2W+FeaJla
            wHjdaFOG0o5Z9KBrQHkvSmB96J5xrpg3qV/1367j/GHpalHX/nEC9iZbDsWPSecl
            113CPiy30xPQ0wyXq1gI60aA6ioxhmTNN5u+su0ciEwGWnCbofzdrmqpntmy9F3w
            ma5ank0pAoGBAO4c1rvS/KfRnZo3sPajvoFqyI6fmMRkuBjfTXky3nJjOSxPKNqR
            RQmtF9yxf23bjEWol1SWjrnjPI+DN0wT5P4mz6QF8/PSsViInMWTYNzZVLHh62sn
            uNFiRQC7p7Mo9Ci2zKZ6GNKaBNjcmenQ6VJNsoY8Ndb71ykXmUgELsA3AoGBAOe+
            FKiX/r5R+OtCkRxVdaTo7JMk7EFbmqknt84SwyXCDFu4huRXLRmCWYE52ppgbuze
            HLn8JmqeIbSEFBU9cfFR4EAYDyik0IBOep86AXjNGy7rtmAgTOXxE9lRiIDP06AG
            DgqF7PgpMDewDQ/+D1cpZ99TAwm4v1Z+rFXVVkkNAoGBAKHj/aNqCdnXzL2ji6/F
            GKtI/N7rZ6RvjjNq73OtwEwpZh/YGkCwcC3p/8VO8QKyOKbLv0gFrTh5ZR1160zQ
            YeriXF56pahq4aT+DQjP8RV2tfzTS4ppUWEa3StoataGy6o6zt2JOgNGMHF5WzP7
            lAcfSHe3zCtEwr7vionKPjb1AoGAMCk8udz8wCjhBmOLLMxF6sPNhrcBsoOLHOR4
            OoeDrvEpCFbNEd9cLBT+7PBNEhBAfVGbvrs8cKP0dUONuOxQJcrSQ/+8BsJZ4pBs
            w3KWo7hckd/Cwy9zS8ZSTbO4Hq0SWgtoF5/Fo71LnAcmb9Bo98BPKgZidz7B5QPm
            ZOA1UnECgYASO1p4Z8LdtVfOlJeegbd0E8CW40DBghbhsdT4v+whNfqM69iHI4XT
            K3sPevwBI7smMaaR0qtkyzmL0qmkWWki6Yf1wUXt+5wKOXds7RfjTqhf709LCkQT
            f9kW8Npa/9LipeWLwx5KpSh+UwNvUFBvP4B6vHZS9rUal5kv/U/EiQ==
            -----END RSA PRIVATE KEY-----
          pubkey: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDXjNJh69we/GOIGq9kvlHB8xwNn3iX1/po28qEOq8UekcgjsxrxUfzknqKD2swAJpDnzr1hA//Yzkgc3SgzUWLb1Sn6+I/CIHjyH/ETfKYa9889et9UX8wwCbtoW4KqvpV/CkYrmNDySw2ATJK791sV0EAhFHY9WkrmZIyyqs5pvTN6zqV2h8dfJmvRhPy0u878Np9ZI2nsseILK+gHK/maZFJlwseGSILg/bZ4UNjEdH6Fn0GYxS6x2J42PH1MHVtU1czb2RD4UKTBFqQfrK9GDh7EcFnmNWc4lFYRnYw1UpAXBi/lRe1kphyLpeeHIusvVPK69eRchxRZb7gqXHL coolnick@coolhost
          privkey_location: {{ home_dir }}/.ssh/cfg_ro.key
          pubkey_location: {{ home_dir }}/.ssh/cfg_ro.key.pub
          override: False
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
          - vim-gtk3
          - python3-pip
    dotfile:
      repo: https://github.com/kiemlicz/ambassador.git
      branch: test-dotfiles
      root: {{ home_dir }}
      post_cmds:
        - "fc-cache -vf ~/.fonts"
    git:
      user.name: coolnick
      user.email: coolnick@gmail.com


{% set owner = username %}

gradle:
  owner: {{ owner }}
intellij:
  owner: {{ owner }}
  owner_link_location: {{ home_dir }}/bin/idea
maven:
  owner: {{ owner }}
rebar:
  owner: {{ owner }}
  owner_home_dir: {{ home_dir }}
robomongo:
  owner: {{ owner }}
  owner_link_location: {{ home_dir }}/bin/robomongo
scala:
  owner: {{ owner }}
mongodb:
  setup_type: single
  install_type: repo
  docker:
    name: mongo-dev
redis:
  setup_type: cluster
  install_type: repo
