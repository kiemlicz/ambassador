import logging
from typing import List

log = logging.getLogger(__name__)


def requisite_commands(required_pkgs: List[str], required_pip: List[str]) -> List[str]:
    # latest pip typically is required, cannot upgrade it in one run as some dependencies may require latest pip
    return [
        f"apt update -y && apt install -y {' '.join(required_pkgs)}",
        f"salt-pip install {' '.join(required_pip)}"
    ]

def salt_download_and_install_commands(
        start_daemon: bool = True,
        salt_version: str = None,
        bootstrap_url="https://bootstrap.saltproject.io"
) -> List[str]:
    """
    Executing list of commands instead of programmatic download to have common base for docker and other deployments
    :param start_daemon: run salt after install
    :return: the list of commands
    """
    loc = "/tmp/bootstrap-salt.sh"
    install = f"sh {loc} -U -x python3"
    if not start_daemon:
        install += " -X"
    if salt_version:
        log.info(f"Will install Salt version: {salt_version}")
        install += salt_version
    return [
        f"curl -o {loc} -L {bootstrap_url}",
        install
    ]


def salt_run_commands() -> List[str]:
    return [
        "salt-call --local saltutil.sync_all",
        "salt-call --local state.highstate"
    ]
