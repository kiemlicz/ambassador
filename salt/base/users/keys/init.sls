include:
  - users.keys.ssh
  - users.keys.gpg

keypairs_generation_completed:
  test.show_notification:
    - name: Keypairs import completed
    - text: Keypair already exists or was not specified
