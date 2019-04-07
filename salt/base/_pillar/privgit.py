import collections
import logging
import os
import re
import copy

import salt.loader
import salt.utils
import salt.utils.dictupdate
import salt.utils.gitfs
from salt.exceptions import SaltConfigurationError

log = logging.getLogger(__name__)

__virtualname__ = 'privgit'


def __virtual__():
    privgit_ext_pillars = [x for x in __opts__['ext_pillar'] if 'privgit' in x]
    if not privgit_ext_pillars:
        # No privgit configured, don't load then
        return False
    return __virtualname__


def ext_pillar(minion_id, pillar, *args, **kwargs):
    '''
    Custom git pillar that can be set up in the runtime via other pillar data
    Read more at envoy README.md file
    Use:
    privkey_location
    pubkey_location
    to point to ssh keypair on master
    or 
    privkey
    pubkey
    with raw content (instead of *_location)
    '''

    def fail(ex): raise ex

    def read_configuration(key, d):
        return d[key] if key in d else fail(SaltConfigurationError("option: {} not found in configuration".format(key)))

    def deflatten_pillar():
        privgit_pattern = re.compile("privgit_\S+_\S+")
        d = []
        for e in (e for e in pillar if privgit_pattern.match(e) is not None):
            value = pillar[e]
            keys = e[8:].split('_', 1)
            d.append({keys[0]: {
                keys[1]: value
            }})
        return d

    def merge(input_dict, output_dict):
        for e in input_dict:
            output_dict = salt.utils.dictupdate.merge(
                output_dict,
                e,
                strategy='smart',
                merge_lists=True
            )
        return output_dict

    def write_file(path, content, perms):
        __salt__['file.write'](path, content)
        __salt__['file.set_mode'](path, perms)

    ext_name = 'privgit'
    opt_url = 'url'
    opt_branch = 'branch'
    opt_env = 'env'
    opt_root = 'root'
    opt_privkey = 'privkey'
    opt_pubkey = 'pubkey'
    opt_privkey_loc = 'privkey_location'
    opt_pubkey_loc = 'pubkey_location'

    cachedir = __salt__['config.get']('cachedir')
    repositories = collections.OrderedDict()

    repositories = merge(args, repositories)
    repositories = merge(pillar[ext_name] if ext_name in pillar else [], repositories)
    repositories = merge(deflatten_pillar(), repositories)

    log.info("Using following repositories: {}".format(repositories))
    ret = {}
    for repository_name, repository_opts in repositories.items():
        if opt_privkey in repository_opts and opt_pubkey in repository_opts:
            parent = os.path.join(cachedir, ext_name, minion_id, repository_name)
            if not os.path.exists(parent):
                os.makedirs(parent)
            priv_location = os.path.join(parent, 'priv.key')
            pub_location = os.path.join(parent, 'pub.key')
            # will override if already exists
            write_file(priv_location, repository_opts[opt_privkey], "600")
            write_file(pub_location, repository_opts[opt_pubkey], "644")
            repository_opts[opt_privkey_loc] = priv_location
            repository_opts[opt_pubkey_loc] = pub_location

        privgit_url = read_configuration(opt_url, repository_opts)
        privgit_branch = read_configuration(opt_branch, repository_opts)
        privgit_env = read_configuration(opt_env, repository_opts)
        privgit_root = read_configuration(opt_root, repository_opts)
        privgit_privkey = read_configuration(opt_privkey_loc, repository_opts)
        privgit_pubkey = read_configuration(opt_pubkey_loc, repository_opts)
        repo = {'{} {}'.format(privgit_branch, privgit_url): [
            {"env": privgit_env},
            {"root": privgit_root},
            {"privkey": privgit_privkey},
            {"pubkey": privgit_pubkey}]}

        log.debug("generated private git configuration: {}".format(repo))

        try:
            # workaround, otherwise GitFS doesn't perform fetch and "remote ref does not exist"
            local_opts = copy.deepcopy(__opts__)
            local_opts['__role'] = 'minion'
            loaded_pillar = salt.loader.pillars(local_opts, __salt__)
            ret = loaded_pillar['git'](minion_id, pillar, repo)
        except Exception as e:
            log.exception(
                "Fatal error in privgit, for: {} {}, repository will be omitted".format(privgit_branch, privgit_url))

    return ret
