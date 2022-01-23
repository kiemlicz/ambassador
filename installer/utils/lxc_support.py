import logging
import sys

HAS_LXC_LIBS = True
try:
    import lxc
except ImportError:
    HAS_LXC_LIBS = False
log = logging.getLogger(__name__)

DEBIAN_RELEASE = "bullseye"
DEBIAN_ARCH = "amd64"


def ensure_container(container_name: str, autostart: bool, ifc: str) -> lxc.Container:
    c = lxc.Container(name=container_name)
    if not c.defined:
        # two interfaces?
        c.set_config_item("lxc.net.0.type", "veth")
        c.set_config_item("lxc.net.0.link", ifc)
        c.set_config_item("lxc.net.0.flags", "up")
        # I think this uses lxc-generate-aa-rules.py
        c.set_config_item("lxc.apparmor.profile", "generated")
        c.set_config_item("lxc.apparmor.allow_nesting", "1")

        if autostart:
            c.set_config_item("lxc.start.auto", "1")
        # todo increase size
        if not c.create(template="debian", flags=0, args={"release": DEBIAN_RELEASE, "arch": DEBIAN_ARCH}):
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
