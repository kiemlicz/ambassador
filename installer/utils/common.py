import argparse
import datetime
import itertools
import logging
import os
import re
import ssl
import subprocess
from distutils import dir_util
from pathlib import Path
from shutil import copyfile
from typing import Dict, List, Tuple, Union, Iterator, Any

log = logging.getLogger(__name__)


def transfer(files: Iterator[Tuple[str, str]]) -> None:
    for src, dst in files:
        Path(dst).parent.mkdir(parents=True, exist_ok=True)
        if os.path.isfile(src):
            log.debug(f"Copying file: {src} -> {dst}")
            copyfile(src, dst)
        elif os.path.isdir(src):
            log.debug(f"Copying directory: {src} -> {dst}")
            dir_util.copy_tree(src, dst)
        else:
            log.error(f"Omitting: {src} as neither file nor directory")


def mappings(input: List[str], dst_dir: str) -> Iterator[Tuple[str, str]]:
    """

    :param input:
    :param dst_dir:
    :return: Both: file and dir mappings
    """
    files = []
    dirs = []
    for i in input:
        if i is not None and os.path.isfile(i):
            files.append(i)
        elif i is not None and os.path.isdir(i):
            dirs.append(i)
        else:
            log.warning(f"{i} omitted since not dir not file")
    return itertools.chain(file_mappings(files, dst_dir), dir_mappings(dirs, dst_dir))  # concat


def file_mappings(input: List[str], dst_dir: str) -> Iterator[Tuple[str, str]]:
    """

    :param input: list of files to be copied to dst_dir
    :param dst_dir: destination
    :return: iterator of tuples (src -> dst) ready to copy
    """
    src_files = list(filter(lambda i: i is not None and os.path.isfile(i), input))
    dst_files = list(map(lambda i: os.path.join(dst_dir, os.path.basename(i)), src_files))
    return zip(src_files, dst_files)


def dir_mappings(input: List[str], dst_dir: str) -> Iterator[Tuple[str, str]]:
    """

    :param input: list of directories to be copied to dst_dir
    :param dst_dir: destination
    :return: iterator of tuples (src -> dst) ready to copy
    """
    src_dirs = list(filter(lambda i: i is not None and os.path.isdir(i), input))
    dst_dirs = list(map(lambda i: os.path.join(dst_dir, os.path.basename(os.path.normpath(i))), src_dirs))
    return zip(src_dirs, dst_dirs)


def dir_content_mappings(input: List[str], dst_dir: str) -> Iterator[Tuple[str, str]]:
    for directory in input:
        for root, _, files in os.walk(directory):
            for file in files:
                full_path = os.path.join(root, file)
                relative_path = os.path.relpath(full_path, start=directory)
                yield full_path, os.path.join(dst_dir, relative_path)


def create(configs: Iterator[Tuple[str, str]]):
    for contents, dst in configs:
        Path(os.path.dirname(dst)).mkdir(parents=True, exist_ok=True)
        with open(dst, 'w') as f:
            f.write(contents)


def measure_time(phase):
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


def join_commands(commands: List[str]) -> str:
    return " && ".join(commands)


def assert_ret_code(command: Union[List[str], str], env: Dict[str, str] = None) -> None:
    if env is None:
        env = os.environ.copy()
    if isinstance(command, list):
        command = join_commands(command)
    completion = subprocess.run(command, shell=True, env=env)
    if completion.returncode:
        raise RuntimeError(f"Command {command} failed with result: {completion}")


def remove_comment(line: str) -> str:
    return re.sub(r"#.*$", "", line)


def flatten(l: List[List[Any]]) -> List[Any]:
    return [e for sub in l for e in sub]


class ExtraArg(argparse.Action):
    def __call__(self, parser, namespace, values, option_string=None):
        s, d = values.split(",")
        if hasattr(namespace, "extra") and getattr(namespace, "extra") is not None:
            namespace.extra.append((s, d))
        else:
            setattr(namespace, "extra", [(s, d)])


class EnvDefault(argparse.Action):
    """
    Precedence: CLI, ENV, default
    """

    def __init__(self, envvar, required=True, default=None, **kwargs):
        if envvar and envvar in os.environ:
            default = os.environ[envvar]
        if required and default:
            required = False
        super(EnvDefault, self).__init__(default=default, required=required, **kwargs)

    def __call__(self, parser, namespace, values, option_string=None):
        setattr(namespace, self.dest, values)


def env_default(envvar):
    def wrapper(**kwargs):
        return EnvDefault(envvar, **kwargs)

    return wrapper
