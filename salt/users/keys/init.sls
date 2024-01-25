include:
  - users.keys.ssh
  - users.keys.gpg

keypairs_generation_completed:
  test.succeed_without_changes:
    - name: Keypairs import completed
