# -*- coding: utf-8 -*-
'''
KDBX SDB module

'''
import logging
import salt.exceptions

try:
    import pykeepass
    HAS_LIBS = True
except ImportError:
    HAS_LIBS = False

log = logging.getLogger(__name__)

__func_alias__ = {
    'set_': 'set'
}


def __virtual__():
    return True if HAS_LIBS else (False, "pykeepass not found")


def get(key):
    raise salt.exceptions.NotImplemented()


def set_(key, value):
    raise salt.exceptions.NotImplemented()
