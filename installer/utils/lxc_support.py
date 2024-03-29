import logging
import sys

import lxc

log = logging.getLogger(__name__)

DEBIAN_RELEASE = "bullseye"
DEBIAN_ARCH = "amd64"
DEBIAN_TEMPLATE = "debian"


def ensure_container(
        container_name: str,
        autostart: bool,
        ifc: str,
        **kwargs
) -> lxc.Container:
    c = lxc.Container(name=container_name)
    if not c.defined:
        # two interfaces?
        c.set_config_item("lxc.net.0.type", "veth")
        c.set_config_item("lxc.net.0.link", ifc)
        c.set_config_item("lxc.net.0.flags", "up")
        c.set_config_item("lxc.net.0.hwaddr", "32:C9:55:54:5E:DF")
        # I think this uses lxc-generate-aa-rules.py
        c.set_config_item("lxc.apparmor.profile", "generated")
        c.set_config_item("lxc.apparmor.allow_nesting", "1")

        release = DEBIAN_RELEASE
        if 'release' in kwargs:
            release = kwargs['release']
        template = DEBIAN_TEMPLATE
        if 'template' in kwargs:
            template = kwargs['template']

        if autostart:
            c.set_config_item("lxc.start.auto", "1")
        # todo increase size
        if not c.create(template=template, flags=0, args={"release": release, "arch": DEBIAN_ARCH}):
            log.error("Unable to create LXC container")
            sys.exit(3)
    if not c.running:
        log.info(f"Starting {container_name}")
        if not c.start():
            log.error(f"Unable to start {container_name}, check output of command: lxc-start -n {container_name} -F")
            sys.exit(4)
        if not c.get_ips(timeout=60):
            log.error("Unable to start LXC container")
            sys.exit(5)
    return c


def remove_container(container_name: str) -> None:
    c = lxc.Container(name=container_name)
    if not (c.shutdown() and c.destroy()):
        log.error(f"Cannot remove container: {container_name}")
