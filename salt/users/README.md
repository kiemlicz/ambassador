`users` dict contains data (mostly self-describing) about particular... user.
However some sections need more description:

#### users:<username>:sec 
Designed to generate/copy user security keys/keypairs.  
For now only ssh is supported. 

When only `privkey_location` and `pubkey_location` is defined then keypair is generated on _minion_.
On the other hand, if `privkey` and `pubkey` is also defined then its content is used as keys. 

Content can be passed also using 'flat' pillar using following form: `<username>_sec_ssh_<name>_privkey` (in our example main keypair can be specified using: `coolguy_sec_ssh_home_privkey: <key>`)

#### dotfile 
TODO
