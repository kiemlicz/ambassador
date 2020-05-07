import argparse
import datetime
import logging
import os
import urllib.request
import sys
import yaml
import lxc
import ssl
import encodings.idna
from distutils import dir_util
from pathlib import Path
from shutil import copyfile
from pykeepass import PyKeePass

log = logging.getLogger()
log.setLevel(logging.INFO)

parser = argparse.ArgumentParser(description='Setup LXC container and provision with Salt')
parser.add_argument('--lxc', help="install within LXC container", required=False, default=False, action='store_true')
parser.add_argument('--name', help="provide container name", required=False)
parser.add_argument('--ifc', help="provide interface to attach container to", required=True)
parser.add_argument('--configs', help="provide Salt Minion config", required=True, nargs='+', type=str)
parser.add_argument('--directories', help="provide directories to copy to container (/srv)", required=False, nargs='+', type=str, default=["salt"])
parser.add_argument('--top', help="provide top.sls file", required=False, type=str)
parser.add_argument('--top-location', help="provide top.sls file location", required=False, type=str, default="/srv/salt/base")
parser.add_argument('--kdbx', help="KDBX file containing further secrets", required=False)
parser.add_argument('--kdbx-pass', help="KDBX password", required=False)
parser.add_argument('--kdbx-key', help="KDBX key file", required=False)
parser.add_argument('--rootfs', help="provide container rootfs path", required=False, default=os.path.join(os.sep, "var", "lib", "lxc"))
parser.add_argument('--autostart', help="should the container autostart", required=False, default=True, action='store_true')
args = parser.parse_args()

use_lxc = args.lxc
prereq_url = "https://gist.githubusercontent.com/kiemlicz/1aa8c2840f873b10ecd744bf54dcd018/raw/1fb26207f7d9665989fc7019b1c0ac919383331a/setup_salt_requisites.sh"
bootstrap_url = "https://bootstrap.saltstack.com"


def ensure_container(container_name):
    c = lxc.Container(name=container_name)
    if not c.defined:
        # two interfaces?
        c.set_config_item("lxc.net.0.type", "veth")
        c.set_config_item("lxc.net.0.link", args.ifc)
        c.set_config_item("lxc.net.0.flags", "up")
        c.set_config_item("lxc.apparmor.profile",
                          "unconfined")  # todo otherwise apache2 won't start, find proper solution

        if args.autostart:
            c.set_config_item("lxc.start.auto", "1")
        # todo increase size
        if not c.create(template="debian", flags=0, args={"release": "buster", "arch": "amd64"}):
            log.error("Unable to create LXC container")
            sys.exit(3)
    if not c.running:
        log.info("Starting %s", container_name)
        if not c.start():
            log.error("Unable to start %s, check output of command: lxc-start -n %s -F", container_name, container_name)
            sys.exit(3)
        if not c.get_ips(timeout=60):
            log.error("Unable to start LXC container")
            sys.exit(3)
    return c


def populate_files(rootfs):
    log.info("Inserting files")
    for dir in args.directories:
        log.info("Copying directory: %s", dir)
        dir_util.copy_tree(dir, os.path.join(rootfs, "srv", dir))

    if args.top:
        l = args.top_location
        if l.startswith("/"):
            l = l[1:]
        dest = os.path.join(rootfs, l, "top.sls")
        log.info("Copying: %s, into: %s", args.top, dest)
        copyfile(args.top, dest)

    Path(os.path.join(rootfs, "etc", "salt", "minion.d")).mkdir(parents=True, exist_ok=True)
    for config in args.configs:
        log.info("Copying Salt config: %s", config)
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
            log.warning("No secrets for: %s found", container_name)


def install():
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    response = urllib.request.urlopen(prereq_url, context=ctx)
    prereq_script = response.read().decode('utf-8')
    response = urllib.request.urlopen(bootstrap_url, context=ctx)
    bootstrap_script = response.read().decode('utf-8')
    with open("/tmp/prereq.sh", "w+") as prereq, open("/tmp/bootstrap-salt.sh", "w+") as bootstrap:
        prereq.write(prereq_script)
        bootstrap.write(bootstrap_script)
    os.chmod("/tmp/prereq.sh", 0o755)
    os.chmod("/tmp/bootstrap-salt.sh", 0o755)
    os.system("/tmp/prereq.sh")
    os.system("/tmp/bootstrap-salt.sh -x python3")
    os.system("gpg --homedir /etc/salt/gpgkeys --import /etc/salt/keys/pillargpg.gpg")
    os.system("salt-call --local saltutil.sync_all")
    os.system("salt-call --local state.highstate")


start_time = datetime.datetime.now()

if use_lxc:
    log.info("Installing into LXC container")
    container_name = args.name
    c = ensure_container(container_name)
    populate_files(os.path.join(args.rootfs, container_name, "rootfs"))
    log.info("Running inside: %s", container_name)
    c.attach_wait(install)
else:
    log.info("Installing directly onto this host")
    populate_files(os.sep)
    install()

end_time = datetime.datetime.now()
log.info("Completed: %s", end_time - start_time)
