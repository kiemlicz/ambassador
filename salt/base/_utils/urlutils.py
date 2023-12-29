try:
    from six.moves.urllib.parse import urlparse, parse_qs

    HAS_URLPARSE = True
except ImportError:
    HAS_URLPARSE = False


def __virtual__():
    return HAS_URLPARSE


def has_libs():
    return __virtual__()


def query_string_to_dict(qs):
    query_dict = parse_qs(qs)

    # unwrap values as by default arguments are parsed to lists { 'k': ['v']}
    for k, v in query_dict.items():
        if isinstance(v, list) and len(v) == 1:
            query_dict[k] = v[0]

    return query_dict
