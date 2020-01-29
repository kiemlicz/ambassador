# -*- coding: utf-8 -*-
'''
KDBX SDB module

'''
import logging

try:
    from pykeepass import PyKeePass
    from salt.ext.six.moves.urllib.parse import urlparse
    HAS_LIBS = True
except ImportError:
    HAS_LIBS = False

log = logging.getLogger(__name__)


def __virtual__():
    return HAS_LIBS


def has_libs():
    return __virtual__()


# memoize will help to not re-load DB during just this call only, but I'm not so sure it is security-wise
# use argon2 DB encryption since it's way faster
def load(kdbx_settings):
    log.warning("CTX1:\n{}".format(id(__context__)))
    db_file = kdbx_settings['db_file']
    if 'kdbx' in __context__ and db_file in __context__['kdbx']:
        log.warning("KDBX {} found in cache".format(db_file))
        return __context__['kdbx'][db_file]
    log.warning("NOT found in cache: {}".format(__context__))
    password = kdbx_settings['password'] if 'password' in kdbx_settings else None
    key_file = kdbx_settings['key_file'] if 'key_file' in kdbx_settings else None
    db = PyKeePass(db_file, password, key_file)
    if 'kdbx' in __context__:
        __context__['kdbx'].update({
            db_file: db
        })
    else:
        __context__.update({
            'kdbx': {
                db_file: db
            }
        })
    log.warning("CTX2:\n{}".format(id(__context__)))
    return db
