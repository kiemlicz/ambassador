import argparse
import io
import logging
import os
from pathlib import Path
from typing import Tuple, List

from utils import commands
from utils import common
# import encodings.idna
from utils.common import dir_mappings, dir_content_mappings, file_mappings, env_default, flatten, ExtraArg

# no point in bloating args with these
LXC_ROOTFS = os.path.join(os.sep, "var", "lib", "lxc")
SALT_KEY_LOCATION = os.path.join(os.sep, "etc", "salt", "keys")
SALT_MINION_CONFIG = os.path.join(os.sep, "etc", "salt", "minion.d")
SALT_TREE_ROOT = os.path.join(os.sep, "srv")
SALT_GPG_LOCATION = os.path.join(os.sep, "etc", "salt", "gpgkeys")
REQUIRED_PKGS_BASE = ["python3-pip", "libssl-dev", "rustc", "curl", "swig"]  # deb only
REQUIRED_PKGS = {
    "ubuntu": REQUIRED_PKGS_BASE + ["libgit2-28"],
    "debian": REQUIRED_PKGS_BASE + ["libgit2-1.5"]
}
REQUIRED_CONTAINER_PKGS = {
    "podman": [],
    "docker": ["dumb-init"]
}
MAIN_FILES_TO_TRANSFER = ['salt']
CONFIGS_TO_TRANSFER = [
    "config/ambassador-installer.conf"
]  # , f"config/ambassador-installer.override.conf"  ### FIXME ADD THIS OVERRIDE SINCE IT WILL BE FILTERED OUT if not exists
BASE_OS = "debian"
BASE_OS_RELEASE = "bookworm"
SALT_DOWNLOAD_URL = "https://bootstrap.saltproject.io"

"""
If running in VM, ensure that NIC promisc mode works
"""
parser = argparse.ArgumentParser(
    description='Installs Salt Minion for further masterless box provisioning. Uses host directly, LXC, Docker or Podman container'
)  # fixme - the idea is to use this install script everywhere (ambassador setup, test setup) so that no setup duplication occurs
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
    nargs="+",
    type=argparse.FileType('r'),
    default=[open("config/requirements.txt", "r", encoding="utf-8")]  # todo handle close
)
parser.add_argument(
    '--configs',
    help="Ambassador configuration file list",
    required=False,
    nargs='+',
    default=CONFIGS_TO_TRANSFER
)
parser.add_argument(
    '--extra',
    help="Extra mappings to add",
    required=False,
    default=[],
    action=ExtraArg,
)
parser.add_argument(
    "--secrets",
    help="Directory were secrets (salt keys) can be found",
    required=False
)

parser.add_argument(
    "--base-os",
    help="Base image if deploying to docker or LXC",
    required=False,
    default=f"{BASE_OS}:{BASE_OS_RELEASE}"
)
parser.add_argument("--tag", help="Docker/Podman tag for resulting image", required=False, default="latest")
parser.add_argument(
    "--target",
    help="Dockerfile's/Containerfile's target to build: salt-minion, salt-master, salt-test",
    required=False, default="salt-test"
)
parser.add_argument(
    '--autostart', help="should the LXC container autostart", required=False, default=False,
    action='store_true'
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
parser.add_argument(
    '--salt-ver',
    help="Salt version to install, e.g. 'git 2019.2.2', latest stable by default",
    required=False,
    action=env_default("SALT_VER"),
    default=""
)
args = parser.parse_args()

logging.basicConfig(
    format='[%(asctime)s] [%(levelname)-8s] %(message)s',
    level=logging.getLevelName(args.log.upper()),
    datefmt='%Y-%m-%d %H:%M:%S'
)
log = logging.getLogger(__name__)

HAS_LXC_LIBS = True
try:
    from utils import lxc_support
except ImportError:
    log.exception("LXC requirements problem")
    HAS_LXC_LIBS = False

HAS_OCI_LIBS = True
try:
    from utils import oci_support
except ImportError:
    log.exception("Docker requirements problem")
    HAS_OCI_LIBS = False

salt_version = args.salt_ver
secrets = args.secrets  # rename to `secrets`
configs = args.configs
where_to = args.to
extra = args.extra


# fixme transfer ambassador ssl keypair to ambassador so that sdb REST can use this !!!

def files_to_transfer() -> List[Tuple[str, str]]:
    """

    :return: List of mappings (tuples) src filename -> dst filename
    """
    # todo handle extensions/file_ext todo some files (configs) are provided as default args some are not
    state_tree_mapping = list(dir_mappings(MAIN_FILES_TO_TRANSFER, SALT_TREE_ROOT))  # dir
    salt_conf_mapping = list(file_mappings(configs, SALT_MINION_CONFIG))  # file *.conf
    salt_keys_mapping = list(dir_content_mappings([secrets], SALT_KEY_LOCATION))

    all_files = state_tree_mapping + salt_conf_mapping + salt_keys_mapping + extra
    log.debug(f"Files to transfer: {all_files}")
    return all_files


def required_pip(requirements_files: List[io.TextIOWrapper]) -> List[str]:
    return flatten([list(map(lambda l: common.remove_comment(l).rstrip(), r.readlines())) for r in requirements_files])


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
    common.assert_ret_code(commands.requisite_commands(required_pkgs, required_pip))
    log.info(f"Mandatory requisites installed: {required_pip}")


@common.measure_time("installation")
def install():
    log.info("Installing Salt")
    # TODO this setup is not specific for LXC, should be available everywhere
    pillar_key = os.path.join(SALT_KEY_LOCATION, "pillargpg.gpg")
    common.assert_ret_code(commands.salt_download_and_install_commands(bootstrap_url=SALT_DOWNLOAD_URL))

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
    common.assert_ret_code(commands.salt_run_commands(), env)


@common.measure_time("deployment")
def this_host_deployment():
    log.info("Installing directly onto this host")
    raise NotImplementedError("Install on this host option: not yet available")
    # populate_files(os.sep)
    # requisites()
    # proceed()
    # run()


@common.measure_time("deployment")
def lxc_deployment(name: str, autostart: bool, ifc: str, base_os: str, requirements: List[io.TextIOWrapper], **kwargs):
    if not HAS_LXC_LIBS:
        raise RuntimeError("Missing package, perform: sudo apt install lxc bridge-utils debootstrap python3-lxc")
    # you may want to enable IP forwarding
    # run lxc-checkconfig
    # check: sed -i '/^GRUB_CMDLINE_LINUX/s/"$/cgroup_enable=memory swapaccount=1"/' /etc/default/grub
    # USE_LXC_BRIDGE="false" in /etc/default/lxc-net
    log.info(f"LXC container installation, will attach to: {name}, autostart: {autostart}, detected interface: {ifc}")
    container_name = f"{name}"
    template, release = base_os.rsplit(":", 1)
    ambassador_lxc = lxc_support.ensure_container(
        container_name=container_name,
        autostart=autostart,
        ifc=ifc,
        template=template,
        release=release
    )

    req_pip = required_pip(requirements)

    def prepare_files(container):
        def add_lxc_rootfs(mapping_tuple):
            return mapping_tuple[0], os.path.join(
                os.path.join(LXC_ROOTFS, container, "rootfs"),
                mapping_tuple[1].strip('/')
            )

        common.transfer(
            map(lambda f: add_lxc_rootfs(f), files_to_transfer())
        )

    log.info("Provisioning LXC, inspect logs carefully since LXC doesn't forward exceptions")
    prepare_files(container_name)
    ambassador_lxc.attach_wait(requisites, ([], REQUIRED_PKGS[BASE_OS]))
    ambassador_lxc.attach_wait(install)
    ambassador_lxc.attach_wait(requisites, (req_pip, []))
    ambassador_lxc.attach_wait(run)


@common.measure_time("deployment")
def oci_deployment(
        name: str,
        requirements: List[io.TextIOWrapper],
        base_os: str,
        target: str,
        tag: str,
        **kwargs
):
    if not HAS_OCI_LIBS:
        raise RuntimeError("Missing docker sdk, perform: sudo pip3 install docker")

    # todo implement secrets for OCI
    # secrets = fetch_secrets()
    # common.create(
    #     map(lambda f: add_lxc_rootfs(f), files_to_create(secrets))
    # )

    all_mappings = files_to_transfer()
    base = base_os.rsplit(":", 1)[0]
    req_pip = required_pip(requirements)
    req_pkgs = REQUIRED_PKGS[base] + REQUIRED_CONTAINER_PKGS[kwargs['to']]

    if kwargs['to'] == "docker":
        log.info("Provisioning Docker image")
        dockerfile = oci_support.prepare_dockerfile(
            base_os,
            req_pkgs,
            req_pip,
            all_mappings
        )
        oci_support.build_docker(dockerfile, target, tag)
    elif kwargs['to'] == "podman":
        log.info("Provisioning Podman image")
        dockerfile = oci_support.prepare_containerfile(
            base_os,
            req_pkgs,
            req_pip,
            all_mappings
        )
        oci_support.build_podman(dockerfile, target, tag)


@common.measure_time("uninstall")
def lxc_uninstall(name: str, **kwargs):
    if not HAS_LXC_LIBS:
        raise RuntimeError("Missing package, perform: sudo apt install lxc bridge-utils debootstrap python3-lxc")
    ambassador_container = f"{name}"
    log.info(f"Removing: {ambassador_container}")
    lxc_support.remove_container(ambassador_container)


@common.measure_time("uninstall")
def this_host_uninstall():
    # todo track all files and remove them
    pass


@common.measure_time("uninstall")
def oci_uninstall():
    pass


if __name__ == "__main__":
    def proceed(to: str):
        return {
            'host': this_host_deployment,
            'lxc': lxc_deployment,
            'docker': oci_deployment,
            'podman': oci_deployment
        }[to]


    def uninstall(to: str):
        return {
            'host': this_host_uninstall,
            'lxc': lxc_uninstall,
            'docker': oci_uninstall,
            'podman': oci_uninstall
        }[to]


    # don't accept dirs and configs separately
    kwargs = vars(args)
    if args.uninstall:
        log.info("Ambassador will be removed")
        uninstall(where_to)(**kwargs)
    else:
        log.info("Ambassador will be installed")
        proceed(where_to)(**kwargs)
