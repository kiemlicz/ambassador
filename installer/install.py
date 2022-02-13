import argparse
import io
import json
import logging
import os
import urllib.request
from pathlib import Path
from typing import Tuple, List, Any

import yaml

from utils import common, lxc_support
# import encodings.idna
from utils.common import dir_mappings, file_mappings
from utils.secret import Secret

HAS_LXC_LIBS = True
try:
    import lxc
except ImportError:
    HAS_LXC_LIBS = False

"""
If running in VM, ensure that NIC promisc mode works
"""
parser = argparse.ArgumentParser(
    description='Installs Salt Minion for further masterless box provisioning. Uses host directly or LXC container'
)
parser.add_argument('--to', help="where to install to: host, docker, lxc", required=False, default="host")
parser.add_argument('--name', help="provide container name", required=False)
parser.add_argument(
    '--ifc',
    help="provide interface to attach container to, default interface otherwise",
    required=False,
    default=common.default_ifc()
)
parser.add_argument(
    '--requirements',
    help="pip requirements file",
    required=False,
    type=argparse.FileType('r'),
    default="config/requirements.txt"
)
parser.add_argument("--secrets", help="URL of service providing secrets",
                    required=False)  # support file:// by creating adapter  todo fails if not provided
parser.add_argument("--secrets-certs", help="API client cert", required=False,
                    default=".local/ambassador-installer.crt")
parser.add_argument("--secrets-key", help="API client key", required=False, default=".local/ambassador-installer.key")
parser.add_argument("--secrets-ca", help="CA to verify secret server", required=False, default=".local/ca.crt")
parser.add_argument('--autostart', help="should the LXC container autostart", required=False, default=False,
                    action='store_true')
parser.add_argument('--kdbx', help="KDBX file containing further secrets",
                    required=False)  # fixme replace with libsecret API in salt
parser.add_argument(
    '--kdbx-pass',
    help="KDBX password",
    required=False
)  # fixme avoid passing this, assume that the DB is already open somewhere, no such lib exists
# the problem with kdbx is: we would need to keep kdbx in kdbx in order to have only --secret-api (downloading kdbx)
# so it is better to get rid of kdbx salt integration (replace with some rest api calls)
parser.add_argument(
    '--kdbx-key',
    help="KDBX key file",
    required=False
)
parser.add_argument(
    '--log',
    help="log level (TRACE, DEBUG, INFO, WARN, ERROR)",
    required=False,
    default="INFO"
)
parser.add_argument(
    '--uninstall',
    help="Remove deployment entirely",
    required=False,
    default=False,
    action='store_true'
)
args = parser.parse_args()

logging.basicConfig(
    format='[%(asctime)s] [%(levelname)-8s] %(message)s',
    level=logging.getLevelName(args.log.upper()),
    datefmt='%Y-%m-%d %H:%M:%S'
)
log = logging.getLogger(__name__)
bootstrap_url = "https://bootstrap.saltproject.io"

secrets_api = args.secrets
secrets_client_cert = args.secrets_certs
secrets_client_key = args.secrets_key
secrets_ca = args.secrets_ca
kdbx_file = args.kdbx
kdbx_key = args.kdbx_key
kdbx_pass = args.kdbx_pass
where_to = args.to

# no point in bloating args with these
LXC_ROOTFS = os.path.join(os.sep, "var", "lib", "lxc")
SALT_KEY_LOCATION = os.path.join(os.sep, "etc", "salt", "keys")
SALT_MINION_CONFIG = os.path.join(os.sep, "etc", "salt", "minion.d")
SALT_TREE_ROOT = os.path.join(os.sep, "srv")
SALT_GPG_LOCATION = os.path.join(os.sep, "etc", "salt", "gpgkeys")


# fixme stop using kdbx in salt and integrate with some external pass manager
# how to properly handle transfer of files? e.g. given set of files with their dest (ideally generated dynamically?)
# handle rest calls not here
def files_to_transfer(container_name) -> List[Tuple[str, str]]:
    # todo handle extensions/file_ext todo some files (configs) are provided as default args some are not
    main = ['salt']
    configs = ["config/ambassador-installer.conf", f"config/ambassador-installer.override.{container_name}.conf"]
    state_tree_mapping = list(dir_mappings(main, SALT_TREE_ROOT))  # dir
    salt_conf_mapping = list(file_mappings(configs, SALT_MINION_CONFIG))  # file *.conf
    kdbx_mapping = list(file_mappings([kdbx_file, kdbx_key], SALT_KEY_LOCATION))  # kdbx db to be removed
    all_files = state_tree_mapping + salt_conf_mapping + kdbx_mapping  # + kdbx_keys_mapping + gpg_keys_mapping
    log.debug(f"Files to transfer: {all_files}")
    return all_files


def files_to_create(container_name: str, secret: Secret) -> List[Tuple[Any, str]]:
    def kdbx_config() -> str:
        kdbx_salt_config = {
            'kdbx': {
                'driver': 'kdbx',
                'db_file': os.path.join(SALT_KEY_LOCATION, os.path.basename(kdbx_file))
            }
        }
        if kdbx_key:
            kdbx_salt_config['kdbx']['key_file'] = os.path.join(SALT_KEY_LOCATION, os.path.basename(kdbx_key))
        if kdbx_pass:
            kdbx_salt_config['kdbx']['password'] = kdbx_pass

        return yaml.dump(kdbx_salt_config)

    def secret_keys() -> List[Tuple[str, str]]:
        return [(e['contents'], os.path.join(SALT_KEY_LOCATION, e['filename'])) for e in secret.attachments()]

    gen = [(kdbx_config(), os.path.join(SALT_MINION_CONFIG, "{}-kdbx.conf".format(container_name)))] + secret_keys()
    log.debug(f"Will create following files: {gen}")
    return gen


def fetch_secrets() -> Secret:  # path of downloaded files?
    """

    :param uri:
    :return: secrets json
    """
    if secrets_api:
        ctx = common.default_ssl_context(cafile=secrets_ca)
        ctx.load_cert_chain(certfile=secrets_client_cert, keyfile=secrets_client_key)
        response = urllib.request.urlopen(secrets_api, context=ctx)
        log.debug(f"'{secrets_api}' response: {response.code}")
        if response:
            return Secret(json.loads(response.read().decode('utf-8')))  # todo validate this is dict
        else:
            raise RuntimeError("Configured secrets API didn't respond")
    else:
        return Secret({})


@common.measure_time("requirements")
def requisites(*args) -> None:  # todo how to pass multiple args without accepting only the list?
    # https://github.com/saltstack/salt/issues/24925
    # I guess that due to that issue, it is impossible to use salt to install it's own dependencies and properly reload
    # 1. I've received: SIX version conflict (originally installed as dist-packages, after pip upgrade didn't reload six from site-packages)
    # 2. some type errors when installing gdrive (auth dependencies not reloaded)
    # 3. pip install --upgrade pip
    # lets ensure the absolute salt minion requirements are satisfied
    args = [e for s in args for e in s]  # flatten due to inability to pass multiple args to attach_wait(...)
    if len(args) <= 1:
        raise RuntimeError(
            f"requisites function takes two params: requirements_file and list of packages. Provided (#{len(args)}): {args}"
        )
    required_pip = args[0]
    required_pkgs = args[1]
    log.info("Installing mandatory requirements")

    # apt update auto accept old repo entry for buster
    common.assert_ret_code(f"apt update -y && apt install -y {' '.join(required_pkgs)}")
    # latest pip typically is required, cannot upgrade it in one run as some dependencies may require latest pip
    common.assert_ret_code(f"pip3 install --upgrade pip")
    common.assert_ret_code(f"pip3 install {required_pip}")
    log.info(f"Mandatory requisites installed: {required_pip}")


@common.measure_time("installation")
def install():
    log.info("Installing Salt")
    ctx = common.default_ssl_context()
    response = urllib.request.urlopen(bootstrap_url, context=ctx)
    bootstrap_script = response.read().decode('utf-8')
    pillar_key = os.path.join(SALT_KEY_LOCATION, "pillargpg.gpg")
    with open("/tmp/bootstrap-salt.sh", "w+") as bootstrap:
        bootstrap.write(bootstrap_script)
        os.chmod("/tmp/bootstrap-salt.sh", 0o755)

    common.assert_ret_code("/tmp/bootstrap-salt.sh -U -x python3")

    if os.path.isfile(pillar_key):
        Path(SALT_GPG_LOCATION).mkdir(parents=True, exist_ok=True, mode=0o600)
        common.assert_ret_code(f"gpg --homedir {SALT_GPG_LOCATION} --import {pillar_key}")
    else:
        log.warning(f"{pillar_key} not found")
    log.info("Salt installed")


@common.measure_time("provisioning")
def run():
    env = os.environ.copy()
    env['SHELL'] = "/bin/bash"  # don't propagate SHELL env
    common.assert_ret_code("salt-call --local saltutil.sync_all", env)  # todo use python api?
    common.assert_ret_code("salt-call --local state.highstate", env)


@common.measure_time("deployment")
def this_host_deployment():
    log.info("Installing directly onto this host")
    # populate_files(os.sep)
    # requisites()
    # proceed()
    # run()


@common.measure_time("deployment")
def lxc_deployment(name: str, autostart: bool, ifc: str, requirements: io.TextIOWrapper, **kwargs):
    # you may want to enable IP forwarding
    # run lxc-checkconfig
    # check: sed -i '/^GRUB_CMDLINE_LINUX/s/"$/cgroup_enable=memory swapaccount=1"/' /etc/default/grub
    # USE_LXC_BRIDGE="false" in /etc/default/lxc-net
    if not HAS_LXC_LIBS:
        raise RuntimeError("Missing package, perform: sudo apt install lxc bridge-utils debootstrap python3-lxc")
    log.info(f"LXC container installation, will attach to: {name}, autostart: {autostart}, detected interface: {ifc}")
    container_name = f"{name}"
    secrets = fetch_secrets()
    required_pkgs = ["python3-pip", "libssl-dev", "rustc", "libgit2-28"]
    ambassador_lxc = lxc_support.ensure_container(container_name, autostart, ifc, template="ubuntu", release="focal")

    required_pip = " ".join(
        list(map(lambda l: common.remove_comment(l).rstrip(), requirements.readlines()))
    )

    def prepare_files(container):
        def add_lxc_rootfs(mapping_tuple):
            return mapping_tuple[0], os.path.join(
                os.path.join(LXC_ROOTFS, container, "rootfs"),
                mapping_tuple[1].strip('/')
            )

        common.transfer(
            map(lambda f: add_lxc_rootfs(f), files_to_transfer(container))
        )

        common.create(
            map(lambda f: add_lxc_rootfs(f), files_to_create(container, secrets))
        )

    prepare_files(container_name)

    log.info("Provisioning LXC")
    ambassador_lxc.attach_wait(requisites, (required_pip, required_pkgs))
    ambassador_lxc.attach_wait(install)
    ambassador_lxc.attach_wait(run)


@common.measure_time("uninstall")
def lxc_uninstall(name: str, **kwargs):
    salt_container = f"{name}-salt"
    foreman_container = f"{name}"
    log.info(f"Removing: {salt_container}")
    lxc_support.remove_container(salt_container)
    log.info(f"Removing: {foreman_container}")
    lxc_support.remove_container(foreman_container)


# setup this
# https://docs.saltproject.io/en/latest/ref/renderers/all/salt.renderers.gpg.html#different-gpg-location
# setup pypass

@common.measure_time("deployment")
def docker_deployment():
    pass


@common.measure_time("uninstall")
def this_host_uninstall():
    # todo track all files and remove them
    pass


@common.measure_time("uninstall")
def docker_uninstall():
    pass


if __name__ == "__main__":
    def proceed(to: str):
        return {
            'host': this_host_deployment,
            'lxc': lxc_deployment,
            'docker': docker_deployment
        }[to]


    def uninstall(to: str):
        return {
            'host': this_host_uninstall,
            'lxc': lxc_uninstall,
            'docker': docker_uninstall
        }[to]


    # don't accept dirs and configs separately
    kwargs = vars(args)
    if args.uninstall:
        log.info("Ambassador will be removed")
        uninstall(where_to)(**kwargs)
    else:
        log.info("Ambassador will be installed")
        proceed(where_to)(**kwargs)
