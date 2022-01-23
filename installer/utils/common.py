import datetime
import logging
import os
import ssl
import subprocess
from distutils import dir_util
from pathlib import Path
from shutil import copyfile
from typing import Dict, List, Tuple, Union, Iterator

log = logging.getLogger(__name__)


class KDBXSupport:
    """
    KDBX config dump
    """
    pass


def transfer(files: Iterator[Tuple[str, str]]) -> None:
    for src, dst in files:
        Path(dst).parent.mkdir(parents=True, exist_ok=True)
        if os.path.isfile(src):
            log.debug(f"Copying file: {src} -> {dst}")
            copyfile(src, dst)
        elif os.path.isdir(src):
            log.debug(f"Copying directory: {src}")
            dir_util.copy_tree(src, dst)
        else:
            log.error(f"Omitting: {src} as neither file nor directory")


def file_mappings(input: List[str], dst_dir: str) -> Iterator[Tuple[str, str]]:
    src_files = list(filter(lambda i: os.path.isfile(i), input))
    dst_files = list(map(lambda i: os.path.join(dst_dir, os.path.basename(i)), src_files))
    return zip(src_files, dst_files)


def dir_mappings(input: List[str], dst_dir: str) -> Iterator[Tuple[str, str]]:
    src_dirs = list(filter(lambda i: os.path.isdir(i), input))
    dst_dirs = list(map(lambda i: os.path.join(dst_dir, os.path.basename(os.path.normpath(i))), src_dirs))
    return zip(src_dirs, dst_dirs)


def create(configs: Iterator[Tuple[str, str]]):
    for contents, dst in configs:
        Path(os.path.dirname(dst)).mkdir(parents=True, exist_ok=True)
        with open(dst, 'w') as f:
            f.write(contents)


def exe_time(phase):
    def decor(f):
        def measure(*args, **kwargs):
            start_time = datetime.datetime.now()
            f(*args, **kwargs)
            end_time = datetime.datetime.now()
            log.info(f"[{phase}] Execution time: {end_time - start_time}")

        return measure

    return decor


def default_ifc():
    with open("/proc/net/route") as fh:
        for line in fh:
            fields = line.strip().split()
            if fields[1] != '00000000' or not int(fields[3], 16) & 2:
                # If not default route or not RTF_GATEWAY, skip it
                continue
            return fields[0]


def default_ssl_context(cafile=None):
    ctx = ssl.create_default_context(cafile=cafile)
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_OPTIONAL
    return ctx


def assert_ret_code(command: Union[List[str], str], env: Dict[str, str] = None) -> None:
    if env is None:
        env = os.environ.copy()
    if isinstance(command, str):
        returncode = subprocess.call(command, shell=True, env=env)
    else:
        returncode = subprocess.call(command, env=env)
    if returncode:
        raise RuntimeError(f"Command {' '.join(command)} failed with {returncode}")
