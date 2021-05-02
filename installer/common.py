import datetime
import logging
import ssl
import os

log = logging.getLogger(__name__)


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


def assert_ret_code(command):
    exit_code = os.system(command)
    if exit_code:
        raise RuntimeError(f"Command {command} failed with {exit_code}")