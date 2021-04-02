import argparse
import datetime
import logging
import os
import urllib.request
import sys
import yaml
import ssl
import encodings.idna
from distutils import dir_util
from pathlib import Path
from shutil import copyfile

HAS_PYKEEPASS_LIBS = True
try:
    from pykeepass import PyKeePass
except ImportError:
    HAS_PYKEEPASS_LIBS = False

HAS_LXC_LIBS = True
try:
    import lxc
except ImportError:
    HAS_LXC_LIBS = False

log = logging.getLogger()
log.setLevel(logging.INFO)

parser = argparse.ArgumentParser(description='Installs Salt Minion for further box provisioning. Uses host directly or LXC container')
parser.add_argument('--lxc', help="install within LXC container", required=False, default=False, action='store_true')
parser.add_argument('--name', help="provide container name", required=False)
parser.add_argument('--ifc', help="provide interface to attach container to", required=False)
parser.add_argument('--configs', help="provide Salt Minion config", required=True, nargs='+', type=str)
# parser.add_argument('--pips', help="Required PIP packages", required=False, nargs='+', type=str, default=["pip==20.3.3", "six==1.15.0"])
parser.add_argument('--directories', help="provide directories to copy to container (/srv)", required=False, nargs='+', type=str, default=["salt"])
parser.add_argument('--top', help="provide top.sls file", required=False, type=str)
parser.add_argument('--top-location', help="provide top.sls file location", required=False, type=str, default="/srv/salt/base")
parser.add_argument('--kdbx', help="KDBX file containing further secrets", required=False)
parser.add_argument('--kdbx-pass', help="KDBX password", required=False)
parser.add_argument('--kdbx-key', help="KDBX key file", required=False)
parser.add_argument('--rootfs', help="provide container rootfs path", required=False, default=os.path.join(os.sep, "var", "lib", "lxc"))
parser.add_argument('--autostart', help="should the LXC container autostart", required=False, default=False, action='store_true')
args = parser.parse_args()

use_lxc = args.lxc
bootstrap_url = "https://bootstrap.saltstack.com"


def ensure_container(container_name):
    c = lxc.Container(name=container_name)
    if not c.defined:
        # two interfaces?
        c.set_config_item("lxc.net.0.type", "veth")
        c.set_config_item("lxc.net.0.link", args.ifc)
        c.set_config_item("lxc.net.0.flags", "up")
        # I think this uses lxc-generate-aa-rules.py
        c.set_config_item("lxc.apparmor.profile", "generated")
        c.set_config_item("lxc.apparmor.allow_nesting", "1")

        if args.autostart:
            c.set_config_item("lxc.start.auto", "1")
        # todo increase size
        if not c.create(template="debian", flags=0, args={"release": "buster", "arch": "amd64"}):
            log.error("Unable to create LXC container")
            sys.exit(3)
    if not c.running:
        log.info(f"Starting {container_name}")
        if not c.start():
            log.error(f"Unable to start {container_name}, check output of command: lxc-start -n {container_name} -F")
            sys.exit(3)
        if not c.get_ips(timeout=60):
            log.error("Unable to start LXC container")
            sys.exit(3)
    return c


def populate_files(rootfs):
    log.info("Inserting files")
    for dir in args.directories:
        if not os.path.isdir(dir):
            log.error(f"Omitting: {dir}, since not directory")
            continue
        log.info(f"Copying directory: {dir}")
        dir_util.copy_tree(dir, os.path.join(rootfs, "srv", os.path.basename(os.path.normpath(dir))))

    if args.top:
        l = args.top_location
        if l.startswith("/"):
            l = l[1:]
        dest = os.path.join(rootfs, l, "top.sls")
        log.info(f"Copying: {args.top}, into: {dest}")
        copyfile(args.top, dest)

    Path(os.path.join(rootfs, "etc", "salt", "gpgkeys")).mkdir(parents=True, exist_ok=True, mode=0o700)
    Path(os.path.join(rootfs, "etc", "salt", "minion.d")).mkdir(parents=True, exist_ok=True)
    for config in args.configs:
        log.info(f"Copying Salt Minion config: {config}")
        # todo check without basename
        copyfile(config, os.path.join(rootfs, "etc", "salt", "minion.d", os.path.basename(config)))

    kdbx_salt_config = {'kdbx': {'driver': 'kdbx'}}
    if args.kdbx_key:
        Path(os.path.join(rootfs, "etc", "salt", "keys")).mkdir(parents=True, exist_ok=True)
        key_filename = os.path.basename(args.kdbx_key)
        copyfile(args.kdbx_key, os.path.join(rootfs, "etc", "salt", "keys", key_filename))
        kdbx_salt_config['kdbx']['key_file'] = os.path.join(os.sep, "etc", "salt", "keys", key_filename)
    if args.kdbx_pass:
        kdbx_salt_config['kdbx']['password'] = args.kdbx_pass
    if args.kdbx:
        if not HAS_PYKEEPASS_LIBS:
            raise Exception("Missing module, perform: pip3 install pykeepass")
        Path(os.path.join(rootfs, "etc", "salt", "kdbx")).mkdir(parents=True, exist_ok=True)
        kdbx_filename = os.path.basename(args.kdbx)
        copyfile(args.kdbx, os.path.join(rootfs, "etc", "salt", "kdbx", kdbx_filename))
        kdbx_salt_config['kdbx']['db_file'] = os.path.join(os.sep, "etc", "salt", "kdbx", kdbx_filename)
        kdbx_config = os.path.join(rootfs, "etc", "salt", "minion.d", "{}-kdbx.conf".format(container_name))
        Path(os.path.dirname(kdbx_config)).mkdir(parents=True, exist_ok=True)
        with open(kdbx_config, 'w') as minion_config_file:
            yaml.dump(kdbx_salt_config, minion_config_file)

        log.info("Inserting secrets")
        kdbx = PyKeePass(args.kdbx, args.kdbx_pass, args.kdbx_key)  # fixme how will it behave if no key
        entry = kdbx.find_entries_by_path(container_name, first=True)
        if entry and entry.attachments:
            for attachment in entry.attachments:
                with open(os.path.join(rootfs, "etc", "salt", "keys", attachment.filename), 'wb') as a:
                    a.write(attachment.data)
        else:
            log.warning(f"No secrets for: {container_name} found")


def install():
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    response = urllib.request.urlopen(bootstrap_url, context=ctx)
    bootstrap_script = response.read().decode('utf-8')
    with open("/tmp/bootstrap-salt.sh", "w+") as bootstrap:
        bootstrap.write(bootstrap_script)
    os.chmod("/tmp/bootstrap-salt.sh", 0o755)

    # it seems that OS packages: `libffi-dev zlib1g-dev libgit2-dev git` are somehow not needed for pygit2 to run
    _assert_ret_code("/tmp/bootstrap-salt.sh -U -x python3 -p python3-pip -p rustc -p libssl-dev")  # consider: -p libgit2-dev
    # install required packages manually (since startup states won't be able to reload the main process to enable pygit2)
    _assert_ret_code("pip3 install --upgrade pyOpenSSL pygit2==1.0.3 cherrypy jinja2 PyYAML pykeepass~=4.0.0 gdrive==0.0.7") # fixme must be installed from Salt itself
    if os.path.isfile("/etc/salt/keys/pillargpg.gpg"):
        _assert_ret_code("gpg --homedir /etc/salt/gpgkeys --import /etc/salt/keys/pillargpg.gpg")
    else:
        log.warning("/etc/salt/keys/pillargpg.gpg not found")


def run():
    _assert_ret_code("salt-call --local saltutil.sync_all")
    _assert_ret_code("salt-call --local state.highstate")


def _assert_ret_code(command):
    exit_code = os.system(command)
    if exit_code:
        raise RuntimeError(f"Command {command} failed with {exit_code}")


start_time = datetime.datetime.now()

if use_lxc:
    if not HAS_LXC_LIBS:
        raise Exception("Missing package, perform: sudo apt install python3-lxc")
    container_name = args.name
    log.info(f"Installing into LXC container, will attach to: {container_name}")
    c = ensure_container(container_name)
    populate_files(os.path.join(args.rootfs, container_name, "rootfs"))
    c.attach_wait(install)
    c.attach_wait(run)
else:
    log.info("Installing directly onto this host")
    populate_files(os.sep)
    install()
    run()

end_time = datetime.datetime.now()
log.info(f"Completed: {end_time - start_time}")
