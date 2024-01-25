def pillar_eq(key_1, key_2, fail_if_no_key=True):
    value_1 = __salt__['pillar.get'](key_1, default=None)
    value_2 = __salt__['pillar.get'](key_2, default=None)

    if fail_if_no_key and (value_1 is None or value_2 is None):
        return False

    return value_1 == value_2


def container():
    return lxc() or docker()


def lxc():
    return __salt__['file.directory_exists']("/dev/.lxc") or __salt__['grains.get']("virtual") == "LXC"


def docker():
    return __salt__['grains.get']("virtual_subtype") == "Docker"


# unable to properly detect podman, relying on custom environmental variable
def podman():
    return __salt__['environ.get']("container") == "podman"
