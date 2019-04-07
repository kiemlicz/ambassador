#!py

import logging

log = logging.getLogger(__name__)


def run():
    states = {}

    def _copy_key(location, user, mode=600, contents_pillar=None, source=None, contents=None):
        s = { 'file_ext.managed': [
            { 'name': location },
            { 'user': user },
            { 'mode': mode },
            { 'makedirs': True },
            { 'require': [
                { 'user': user }
            ]}
        ]}
        if contents_pillar:
            s['file_ext.managed'].append({ 'contents_pillar': contents_pillar })
            return s
        elif source:
            s['file_ext.managed'].append({ 'source': source })
            return s
        else:
            s['file_ext.managed'].append({ 'contents': contents })
            return s

    for username, user in __salt__['pillar.get']("users", {}).items():
        if 'sec' in user and 'ssh' in user['sec']:
            if not isinstance(user['sec']['ssh'], dict):
                msg = "<username>:sec:ssh:<keyname>:... must be specified as dict, found: {}".format(type(user['sec']['ssh']))
                log.error(msg)
                raise TypeError(msg)
            for name, key_spec in user['sec']['ssh'].items():
                ssh_priv_flat = "{}_sec_ssh_{}_privkey".format(username, name)
                ssh_pub_flat = "{}_sec_ssh_{}_pubkey".format(username, name)

                if ssh_priv_flat in pillar and ssh_pub_flat in pillar:
                    states["{}_copy_{}_ssh_priv".format(username, name)] = _copy_key(key_spec['privkey_location'], user=username, mode=600, contents_pillar=ssh_priv_flat)
                    states["{}_copy_{}_ssh_pub".format(username, name)] = _copy_key(key_spec['pubkey_location'], user=username, mode=644, contents_pillar=ssh_pub_flat)
                elif 'privkey' in key_spec and 'pubkey' in key_spec:
                    states["{}_copy_{}_ssh_priv".format(username, name)] = _copy_key(key_spec['privkey_location'], user=username, mode=600, contents_pillar="users:{}:sec:ssh:{}:privkey".format(username, name))
                    states["{}_copy_{}_ssh_pub".format(username, name)] = _copy_key(key_spec['pubkey_location'], user=username, mode=644, contents_pillar="users:{}:sec:ssh:{}:pubkey".format(username, name))
                elif 'privkey_source' in key_spec and 'pubkey_source' in key_spec:
                    states["{}_copy_{}_ssh_priv".format(username, name)] = _copy_key(key_spec['privkey_location'], user=username, mode=600, source=key_spec['privkey_source'])
                    states["{}_copy_{}_ssh_pub".format(username, name)] = _copy_key(key_spec['pubkey_location'], user=username, mode=644, source=key_spec['pubkey_source'])
                else:
                    log.info("Insufficient data to copy: {} keypair (no flat pillar, nested pillar or source), generating".format(name))

                    if 'override' in key_spec and key_spec['override'] or not __salt__['file.file_exists'](key_spec['privkey_location']):
                        states["{}_generate_{}_ssh_keys".format(username, name)] = {
                            'file.absent': [
                                { 'names': [
                                    key_spec['privkey_location'],
                                    key_spec['pubkey_location']
                                ]},
                                { 'require': [
                                    { 'user': username }
                                ]}
                            ],
                            'cmd.run': [
                                { 'name': "/usr/bin/ssh-keygen -q -t rsa -f {} -N ''".format(key_spec['privkey_location']) },
                                { 'runas': username },
                                { 'require': [
                                    { 'file': "{}_generate_{}_ssh_keys".format(username, name) }
                                ] }
                            ]
                        }

        if 'sec' in user and 'ssh_authorized_keys' in user['sec']:
            for key_spec in user['sec']['ssh_authorized_keys']:
                id="{}_setup_ssh_authorized_keys".format(username)
                states[id] = {
                    'ssh_auth.present': [
                        { 'user': username }
                    ]
                }
                if 'source' in key_spec:
                    states[id]['ssh_auth.present'].append({ 'source': key_spec['source'] })
                elif 'names' in key_spec:
                    states[id]['ssh_auth.present'].append({ 'names': key_spec['names'] })
                else:
                    states[id]['ssh_auth.present'].append({ 'name': key_spec['name'] })

                if 'enc' in key_spec:
                    states[id]['ssh_auth.present'].append({ 'enc': key_spec['enc'] })

                if 'config' in key_spec:
                    states[id]['ssh_auth.present'].append({ 'config': key_spec['config'] })

    states["keypairs_generation_completed"] = {
        'test.show_notification': [
            { 'name': "Keypairs copy/generation completed" },
            { 'text': "Keypair already exists or was not specified" }
        ]
    }

    return states
