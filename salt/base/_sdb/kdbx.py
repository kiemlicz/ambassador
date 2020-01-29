# -*- coding: utf-8 -*-
'''
KDBX SDB module

'''
import logging
from salt.exceptions import CommandExecutionError

try:
    from pykeepass import PyKeePass
    from salt.ext.six.moves.urllib.parse import urlparse
    HAS_LIBS = True
except ImportError:
    HAS_LIBS = False

log = logging.getLogger(__name__)


def __virtual__():
    if not HAS_LIBS or not __utils__['urlutils.has_libs']():
        # somehow sdb modules doesn't print missing lib message nicely, instead you will just see KeyError 'kdbx.get'
        # that's why this additional log message
        log.error("pykeepass not found")
        return False, "pykeepass/urlparse not found"
    return True


def get(key, profile=None):
    query_parsed = urlparse(key)
    query_dict = __utils__['urlutils.query_string_to_dict'](query_parsed.query)
    filename = query_dict['attachment'] if 'attachment' in query_dict else None
    attributes = query_dict['attributes'] if 'attributes' in query_dict else None

    if filename and attributes:
        raise CommandExecutionError("Cannot fetch both attributes and attachments")

    e = _get_first_entry_by_path(query_parsed.path, profile)
    if not e:
        log.error("KDBX entries by path: {}, didn't return entries".format(query_parsed.path))
        return None

    if attributes:
        p = e.custom_properties
        log.debug("Returning properties dict for key: {}".format(key))
        return {a: p[a] for a in attributes if a in p}
    elif filename:
        attachments = [a.data for a in e.attachments if a.filename == filename]
        if len(attachments) > 1:
            log.warning("Found multiple attachments with filename: {}".format(filename))
        log.debug("Returning attachment data for key: {}".format(key))
        return attachments[0]
    else:
        log.debug("Returning password entry for key: {}".format(key))
        return e.password


def _get_first_entry_by_path(path, profile=None):
    kp = __utils__['kdbx.load'](profile)
    return kp.find_entries_by_path(path=path, first=True)
