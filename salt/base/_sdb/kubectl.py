# -*- coding: utf-8 -*-
'''
Kubernetes SDB module

'''
import logging
import salt.exceptions

try:
    from salt.ext.six.moves.urllib.parse import urlparse, parse_qs
    HAS_LIBS = True
except ImportError:
    HAS_LIBS = False

log = logging.getLogger(__name__)

__func_alias__ = {
    'set_': 'set'
}


def __virtual__():
    return True if HAS_LIBS else (False, "urlparse not found")


def get(key, profile=None):
    query_parsed = urlparse(key)
    query_dict = _query_string_to_dict(query_parsed.query)
    client = _get_client()
    kind = query_parsed.path
    if 'label_selector' in query_dict:
        return client.list(kind, **query_dict)
    else:
        return client.read(kind, **query_dict)


def set_(key, value, profile=None):
    raise salt.exceptions.NotImplemented()


def _query_string_to_dict(qs):
    query_dict = parse_qs(qs)

    # unwrap values as by default arguments are parsed to lists { 'k': ['v']}
    for k, v in query_dict.items():
        if isinstance(v, list) and len(v) == 1:
            query_dict[k] = v[0]

    return query_dict


def _get_client():
    return __utils__['k8s.k8s_client']()
