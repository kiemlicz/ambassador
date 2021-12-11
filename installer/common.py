import datetime
import logging
import os
import ssl
import subprocess
from distutils import dir_util
from pathlib import Path
from shutil import copyfile
from typing import Dict, Any, List, Tuple, Union, Iterator

import yaml

log = logging.getLogger(__name__)


def transfer(files: List[Tuple[str, str]]) -> None:
    for src, dst in files:
        Path(dst).mkdir(parents=True, exist_ok=True)
        if os.path.isfile(src):
            copyfile(src, dst)
        elif os.path.isdir(dst):
            log.info(f"Copying directory: {src}")
            dir_util.copy_tree(src, dst)


def file_mappings(input: List[str], dst_dir: str) -> Iterator[Tuple[str, str]]:
    f = filter(lambda i: os.path.isfile(i), input)
    return zip(f, map(lambda i: os.path.join(dst_dir, os.path.basename(i)), f))


def dir_mappings(input: List[str], dst_dir: str) -> Iterator[Tuple[str, str]]:
    d = filter(lambda i: os.path.isdir(i), input)
    return zip(d, map(lambda i: os.path.join(dst_dir, os.path.basename(os.path.normpath(i))), d))


def generate(config: Dict[str, Any], location: str):
    Path(os.path.dirname(location)).mkdir(parents=True, exist_ok=True)
    with open(location, 'w') as f:
        yaml.dump(config, f)


def exe_time(f):
    def measure(*args, **kwargs):
        start_time = datetime.datetime.now()
        f(*args, **kwargs)
        end_time = datetime.datetime.now()
        log.info(f"Execution time: {end_time - start_time}")

    return measure


def default_ifc():
    with open("/proc/net/route") as fh:
        for line in fh:
            fields = line.strip().split()
            if fields[1] != '00000000' or not int(fields[3], 16) & 2:
                # If not default route or not RTF_GATEWAY, skip it
                continue
            return fields[0]


def default_ssl_context():
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    return ctx


def assert_ret_code(command: Union[List[str], str]) -> None:
    if isinstance(command, str):
        returncode = subprocess.call(command, shell=True)
    else:
        returncode = subprocess.call(command)
    if returncode:
        raise RuntimeError(f"Command {' '.join(command)} failed with {returncode}")
