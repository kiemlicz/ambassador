import lxc
import sys
import os
import argparse
import logging
import yaml
import datetime
from distutils import dir_util
from shutil import copyfile
from pathlib import Path
from pykeepass import PyKeePass


log = logging.getLogger()
log.setLevel(logging.INFO)
parser = argparse.ArgumentParser(description='Setup LXC container and provision with Salt')
parser.add_argument('--name', help="provide container name", required=True)
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

start_time = datetime.datetime.now()
container_name = args.name
c = lxc.Container(name=container_name)

if not c.defined:
    # two interfaces?
    c.set_config_item("lxc.net.0.type", "veth")
    c.set_config_item("lxc.net.0.link", args.ifc)
    c.set_config_item("lxc.net.0.flags", "up")
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

log.info("Inserting files")
container_rootfs = os.path.join(args.rootfs, container_name, "rootfs")
for dir in args.directories:
    log.info("Copying directory: %s", dir)
    dir_util.copy_tree(dir, os.path.join(container_rootfs, "srv", dir))

if args.top:
    copyfile(args.top, os.path.join(container_rootfs, args.top_location, "top.sls"))

Path(os.path.join(container_rootfs, "srv", "keys")).mkdir(parents=True, exist_ok=True)
kdbx_salt_config = {'kdbx': {'driver': 'kdbx'}}
if args.kdbx_key:
    key_filename = os.path.basename(args.kdbx_key)
    copyfile(args.kdbx_key, os.path.join(container_rootfs, "srv", "keys", key_filename))
    kdbx_salt_config['kdbx']['key_file'] = os.path.join(os.sep, "srv", "keys", key_filename)
if args.kdbx_pass:
    kdbx_salt_config['kdbx']['password'] = args.kdbx_pass
if args.kdbx:
    Path(os.path.join(container_rootfs, "srv", "kdbx")).mkdir(parents=True, exist_ok=True)
    kdbx_filename = os.path.basename(args.kdbx)
    copyfile(args.kdbx, os.path.join(container_rootfs, "srv", "kdbx", kdbx_filename))
    kdbx_salt_config['kdbx']['db_file'] = os.path.join(os.sep, "srv", "kdbx", kdbx_filename)
    kdbx_config = os.path.join(container_rootfs, "etc", "salt", "minion.d", "{}-kdbx.conf".format(container_name))
    Path(os.path.dirname(kdbx_config)).mkdir(parents=True, exist_ok=True)
    with open(kdbx_config, 'w') as minion_config_file:
        yaml.dump(kdbx_salt_config, minion_config_file)
    log.info("Inserting secrets")
    kdbx = PyKeePass(args.kdbx, args.kdbx_pass, args.kdbx_key)  # fixme how will it behave if no key
    entry = kdbx.find_entries_by_path(container_name, first=True)
    if entry and entry.attachments:
        for attachment in entry.attachments:
            with open(os.path.join(container_rootfs, "srv", "keys", attachment.filename), 'wb') as a:
                a.write(attachment.data)
    else:
        log.warning("No secrets for: %s found", container_name)

if args.configs:
    for config in args.configs:
        log.info("Copying Salt config: %s", config)
        # todo check without basename
        copyfile(config, os.path.join(container_rootfs, "etc", "salt", "minion.d", os.path.basename(config)))

log.info("Running inside: %s", container_name)
c.attach_wait(lxc.attach_run_command, ["apt-get", "install", "-y", "curl"])
c.attach_wait(lxc.attach_run_command, ["curl", "-o", "/tmp/pre.sh", "-L", "https://gist.githubusercontent.com/kiemlicz/1aa8c2840f873b10ecd744bf54dcd018/raw/1fb26207f7d9665989fc7019b1c0ac919383331a/setup_salt_requisites.sh"])
c.attach_wait(lxc.attach_run_command, ["curl", "-o", "/tmp/bootstrap-salt.sh", "-L", "https://bootstrap.saltstack.com"])
c.attach_wait(lxc.attach_run_command, ["bash", "/tmp/pre.sh"])
c.attach_wait(lxc.attach_run_command, ["bash", "/tmp/bootstrap-salt.sh", "-x", "python3"])
c.attach_wait(lxc.attach_run_command, ["gpg", "--homedir", "/etc/salt/gpgkeys", "--import", "/srv/keys/pillargpg.gpg"])
c.attach_wait(lxc.attach_run_command, ["salt-call", "--local", "saltutil.sync_all"])
c.attach_wait(lxc.attach_run_command, ["salt-call", "--local", "state.highstate"])
end_time = datetime.datetime.now()
log.info("Completed: %s", end_time - start_time)
