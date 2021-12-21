import argparse
import logging
import os
import urllib.request
from typing import Tuple, List, Dict, Any

import requests

from installer import common, lxc_support
# import encodings.idna
from installer.common import dir_mappings, file_mappings

HAS_LXC_LIBS = True
try:
    import lxc
except ImportError:
    HAS_LXC_LIBS = False

"""
If running in VM, ensure that NIC promisc mode works
"""
# fixme add uninstall based on copied files
parser = argparse.ArgumentParser(
    description='Installs Salt Minion for further masterless box provisioning. Uses host directly or LXC container')
parser.add_argument('--to', help="where to install to: host, docker, lxc", required=False, default="host")
parser.add_argument('--name', help="provide container name", required=False)
parser.add_argument('--ifc', help="provide interface to attach container to, default interface otherwise",
                    required=False, default=common.default_ifc())
parser.add_argument('--requirements', help="pip requirements file", required=False, type=argparse.FileType('r'),
                    default="config/requirements.txt")
parser.add_argument('--configs', help="provide Salt Minion config", required=False, nargs='+', type=str,
                    default=["config/ambassador-installer.conf", "config/ambassador-installer.override.conf"])
parser.add_argument('--top', help="provide top.sls file", required=False, type=str,
                    default="config/ambassador-top.sls")  # todo mount from gitfs
parser.add_argument('--top-location', help="provide top.sls file location", required=False, type=str,
                    default="/srv/salt/base")  # todo mount from gitfs
parser.add_argument("--secrets", help="URL of service providing secrets", required=False)
parser.add_argument("--secrets-certs", help="API client cert", required=False,
                    default=".local/ambassador-installer.crt")
parser.add_argument("--secrets-key", help="API client key", required=False, default=".local/ambassador-installer.key")
parser.add_argument('--rootfs', help="provide container rootfs path", required=False,
                    default=os.path.join(os.sep, "var", "lib", "lxc"))
parser.add_argument('--autostart', help="should the LXC container autostart", required=False, default=False,
                    action='store_true')
parser.add_argument('--kdbx', help="KDBX file containing further secrets", required=False)  # replace with libsecret API
parser.add_argument('--kdbx-pass', help="KDBX password",
                    required=False)  # fixme avoid passing this, assume that the DB is already open somewhere, no such lib exists
parser.add_argument('--kdbx-key', help="KDBX key file", required=False)
parser.add_argument('--log', help="log level (TRACE, DEBUG, INFO, WARN, ERROR)", required=False, default="INFO")
args = parser.parse_args()

logging.basicConfig(
    format='[%(asctime)s] [%(levelname)-8s] %(message)s',
    level=logging.getLevelName(args.log),
    datefmt='%Y-%m-%d %H:%M:%S'
)
log = logging.getLogger(__name__)
bootstrap_url = "https://bootstrap.saltproject.io"
main = ['salt']  # todo handle extensions/file_ext
configs = args.configs
secrets_api = args.secrets
secrets_client_cert = args.secrets_cert
secrets_client_key = args.secrets_key

# args?
SALT_KEY_LOCATION = os.path.join(os.sep, "etc", "salt", "keys")
SALT_MINION_CONFIG = os.path.join(os.sep, "etc", "salt", "minion.d")
# fixme breaks logging init
HAS_PYKEEPASS_LIBS = True
try:
    from pykeepass import PyKeePass
except ImportError:
    HAS_PYKEEPASS_LIBS = False


# how to properly handle transfer of files? e.g. given set of files with their dest (ideally generated dynamically?)
# handle rest calls not here
def files_to_transfer(
        kdbx: List[str], gpg_keys: List[str],
        kdbx_keys: List[str]) -> List[Tuple[str, str]]:
    state_tree_mapping = list(dir_mappings(main, os.path.join(os.sep, "srv")))  # dir
    salt_conf_mapping = list(file_mappings(configs, SALT_MINION_CONFIG))  # file *.conf
    kdbx_mapping = list(file_mappings(kdbx, SALT_KEY_LOCATION))  # files
    kdbx_keys_mapping = list(file_mappings(kdbx_keys, SALT_KEY_LOCATION))
    gpg_keys_mapping = list(file_mappings(gpg_keys, SALT_KEY_LOCATION))

    return state_tree_mapping + salt_conf_mapping + kdbx_mapping + kdbx_keys_mapping + gpg_keys_mapping


def fetch_secrets() -> List[str]:  # path of downloaded files?
    cert = (secrets_client_cert, secrets_client_key)
    response = requests.get(secrets_api, cert=cert)
    if response:
        response.json()


def kdbx_config(container_name: str, kdbx_file: str, kdbx_key_file: str = None, kdbx_password: str = None) -> Dict[
    str, Any]:
    if not HAS_PYKEEPASS_LIBS:
        raise Exception("Missing module, perform: pip3 install pykeepass~=4.0.0")

    kdbx_salt_config = {
        'kdbx': {
            'driver': 'kdbx',
            'db_file': os.path.join(os.sep, "etc", "salt", "kdbx", os.path.basename(kdbx_file))
        }
    }
    if kdbx_key_file:
        kdbx_salt_config['kdbx']['key_file'] = os.path.join(os.sep, "etc", "salt", "keys",
                                                            os.path.basename(kdbx_key_file))
    if kdbx_password:
        kdbx_salt_config['kdbx']['password'] = kdbx_password

    # fixme this downlaods the key from kdbx and dumps on LXC
    # kdbx_config = os.path.join(os.sep, "etc", "salt", "minion.d", "{}-kdbx.conf".format(container_name))
    # Path(os.path.dirname(kdbx_config)).mkdir(parents=True, exist_ok=True)
    # with open(kdbx_config, 'w') as minion_config_file:
    #     yaml.dump(kdbx_salt_config, minion_config_file)

    # log.info("Inserting secrets")
    # research if they can be put to config as sdb://
    # kdbx = PyKeePass(args.kdbx, args.kdbx_pass, args.kdbx_key)  # fixme how will it behave if no key
    # entry = kdbx.find_entries_by_path(container_name, first=True)
    # if entry and entry.attachments:
    #     for attachment in entry.attachments:
    #         with open(os.path.join(rootfs, "etc", "salt", "keys", attachment.filename), 'wb') as a:
    #             a.write(attachment.data)
    # else:
    #     log.warning(f"No secrets for: {container_name} found")
    return kdbx_salt_config


def write_keys_from_kdbx(kdbx: PyKeePass, container_name: str, path: str) -> None:
    entry = kdbx.find_entries_by_path(container_name, first=True)
    if entry and entry.attachments:
        for attachment in entry.attachments:
            with open(os.path.join(path, attachment.filename), 'wb') as a:
                a.write(attachment.data)
    else:
        log.warning(f"No secrets for: {container_name} found")


# def populate_files(rootfs):
#     common.transfer(files_to_transfer())

# if args.top:
#     l = args.top_location
#     if l.startswith("/"):
#         l = l[1:]
#     dest = os.path.join(rootfs, l, "top.sls")
#     log.info(f"Copying: {args.top}, into: {dest}")
#     copyfile(args.top, dest)
#
# Path(os.path.join(rootfs, "etc", "salt", "gpgkeys")).mkdir(parents=True, exist_ok=True, mode=0o700)
# Path(os.path.join(rootfs, "etc", "salt", "minion.d")).mkdir(parents=True, exist_ok=True)
# for config in args.configs:
#     log.info(f"Copying Salt Minion config: {config}")
#     # todo check without basename
#     copyfile(config, os.path.join(rootfs, "etc", "salt", "minion.d", os.path.basename(config)))


def requisites(requirements_file):
    # https://github.com/saltstack/salt/issues/24925
    # I guess that due to that issue, it is impossible to use salt to install it's own dependencies and properly reload
    # 1. I've received: SIX version conflict (originally installed as dist-packages, after pip upgrade didn't reload six from site-packages)
    # 2. some type errors when installing gdrive (auth dependencies not reloaded)
    # 3. pip install --upgrade pip
    # lets ensure the absolute salt minion requirements are satisfied
    requirements = " ".join(
        map(lambda l: l.rstrip(), filter(lambda l: not l.startswith("#"), requirements_file.readlines())))
    common.assert_ret_code("apt update && apt install -y python3-pip")
    common.assert_ret_code(f"pip3 install {requirements}")
    log.info(f"Mandatory requisites installed: {requirements}")


def install():
    ctx = common.default_ssl_context()
    response = urllib.request.urlopen(bootstrap_url, context=ctx)
    bootstrap_script = response.read().decode('utf-8')
    with open("/tmp/bootstrap-salt.sh", "w+") as bootstrap:
        bootstrap.write(bootstrap_script)
    os.chmod("/tmp/bootstrap-salt.sh", 0o755)

    # it seems that OS packages: `libffi-dev zlib1g-dev libgit2-dev git` are somehow not needed for pygit2 to run
    # consider: -p libgit2-dev
    common.assert_ret_code("/tmp/bootstrap-salt.sh -U -x python3 -p python3-pip -p rustc -p libssl-dev")
    if os.path.isfile("/etc/salt/keys/pillargpg.gpg"):
        common.assert_ret_code("gpg --homedir /etc/salt/gpgkeys --import /etc/salt/keys/pillargpg.gpg")
    else:
        log.warning("/etc/salt/keys/pillargpg.gpg not found")


def run():
    common.assert_ret_code("salt-call --local saltutil.sync_all")
    common.assert_ret_code("salt-call --local state.highstate")


@common.exe_time
def this_host_deployment():
    log.info("Installing directly onto this host")
    # populate_files(os.sep)
    requisites()
    proceed()
    run()


@common.exe_time
def lxc_deployment(name: str, autostart: bool, ifc: str, requirements: str, **kwargs):
    # you may want to enable IP forwarding
    # run lxc-checkconfig
    # check: sed -i '/^GRUB_CMDLINE_LINUX/s/"$/cgroup_enable=memory swapaccount=1"/' /etc/default/grub
    # USE_LXC_BRIDGE="false" in /etc/default/lxc-net
    if not HAS_LXC_LIBS:
        raise RuntimeError("Missing package, perform: sudo apt install lxc bridge-utils debootstrap python3-lxc")
    log.info(f"LXC container installation, will attach to: {name}, autostart: {autostart}, detected interface: {ifc}")
    c = lxc_support.ensure_container(name, autostart, ifc)
    # populate_files(os.path.join(args.rootfs, name, "rootfs"))

    if secrets_api:
        fetch_secrets()
        # download here
        # add to list of files to transfer

    # todo generation step here (e.g. generate salt configs)
    configs = kwargs['configs']

    common.transfer(
        files_to_transfer()
    )

    c.attach_wait(requisites, requirements)
    # c.attach_wait(install)
    # c.attach_wait(run)


# setup this
# https://docs.saltproject.io/en/latest/ref/renderers/all/salt.renderers.gpg.html#different-gpg-location
# setup pypass

@common.exe_time
def docker_install():
    pass


if __name__ == "__main__":
    def proceed(to: str):
        return {
            'host': this_host_deployment,
            'lxc': lxc_deployment,
            'docker': docker_install
        }[to]


    # don't accept dirs and configs separately

    kwargs = vars(args)
    where_to = args.to
    proceed(where_to)(**kwargs)
