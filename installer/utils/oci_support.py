import logging
import os.path
import textwrap
from pathlib import Path
from typing import List, Tuple

from .commands import requisite_commands, salt_download_and_install_commands
from .common import join_commands, assert_ret_code

log = logging.getLogger(__name__)
CONTAINERFILE_LOCATION = ".local/"


def prepare_dockerfile(
        base_image: str,
        required_pkgs: List[str],
        required_pip: List[str],
        copy_files: List[Tuple[str, str]],
        saltver: str = None
) -> str:
    copy_commands = _copy_commands(copy_files)
    dockerfile = textwrap.dedent(
        f"""\
    # syntax=docker/dockerfile:1.3-labs
    FROM {base_image} as salt-base
    RUN {join_commands(requisite_commands(required_pkgs, required_pip))}
    RUN {join_commands(salt_download_and_install_commands(start_daemon=False, salt_version=saltver))}
{copy_commands}
    WORKDIR /srv
    
    FROM salt-base as salt-minion
    VOLUME /etc/salt/minion.d
    ENTRYPOINT ["/usr/bin/dumb-init", "--"]
    CMD [ "/usr/local/bin/salt-minion" ]
    
    FROM salt-base AS salt-master
    
    COPY <<EOF /opt/entrypoint.sh
      /usr/local/bin/salt-api &
      /usr/local/bin/salt-master &
      wait -n
    EOF
    # todo kubectl binary?
    # todo configurable api
    # todo salt user
    # 
    EXPOSE 4505:4505 4506:4506

    VOLUME /etc/salt/pki/master
    VOLUME /var/cache/salt/master/queues
    VOLUME /etc/pki/tls/certs
    VOLUME /etc/salt/cloud.providers.d
    VOLUME /srv/thorium
    VOLUME /srv/pillar
    VOLUME /etc/salt/master.d
    
    ENTRYPOINT ["/usr/bin/dumb-init", "--"]
    CMD [ "/opt/entrypoint.sh" ]
    """
    )
    log.debug(f"Generated Dockerfile:\n{dockerfile}")
    return dockerfile

def prepare_containerfile(
        base_image: str,
        required_pkgs: List[str],
        required_pip: List[str],
        copy_files: List[Tuple[str, str]],
        saltver: str = None
) -> str:
    copy_commands = _copy_commands(copy_files)  # fixme merge the copy, verify ambassador-test.conf
    containerfile = textwrap.dedent(
        f"""\
    FROM {base_image} as salt-test
    RUN apt update && \
        apt install -y systemd systemd-sysv cron anacron crun &&\
        systemctl mask -- dev-hugepages.mount sys-fs-fuse-connections.mount &&\
        rm -f /etc/machine-id /var/lib/dbus/machine-id
    ENV container podman  # there is no counterpart of .dockerenv in podman
    RUN {join_commands(requisite_commands(required_pkgs, required_pip))}
    RUN {join_commands(salt_download_and_install_commands(start_daemon=False, salt_version=saltver))}
        
{copy_commands}
    
    WORKDIR /opt
    STOPSIGNAL SIGRTMIN+3
    CMD ["/sbin/init"]
    """
    )
    log.debug(f"Generated Containerfile:\n{containerfile}")
    return containerfile


def build_docker(dockerfile: str, target: str, tag: str):
    # not using docker library due to https://github.com/docker/docker-py/issues/2230
    d = _ensure_dir("Dockerfile")
    with open(d, 'w') as f:
        f.write(dockerfile)
    cmd = f"docker build --target {target} -t {tag} -f {d} ."
    env = {"DOCKER_BUILDKIT": "1"}
    assert_ret_code(cmd, env)


def build_podman(containerfile: str, target: str, tag: str):
    d = _ensure_dir("Containerfile")
    with open(d, 'w') as f:
        f.write(containerfile)
    cmd = f"podman build --target {target} -t {tag} -f {d} ."
    assert_ret_code(cmd)


def _ensure_dir(filename: str):
    Path(CONTAINERFILE_LOCATION).mkdir(parents=True, exist_ok=True)
    d = os.path.join(CONTAINERFILE_LOCATION, filename)
    return d


def _copy_commands(copy_files: List[Tuple[str, str]]) -> str:
    return "\n".join(map(lambda t: f"    COPY {t[0]} {t[1]}", copy_files))
