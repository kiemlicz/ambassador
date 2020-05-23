import logging

try:
    import requests
    import urllib.parse

    HAS_LIBS = True
except ImportError:
    HAS_LIBS = False

log = logging.getLogger(__name__)
__virtualname__ = 'foreman'

__opts__ = {
    "foreman.url": "http://foreman/api",
    "foreman.user": "admin",
    "foreman.password": "changeme",
    "foreman.verifyssl": True,
    "foreman.certfile": None,
    "foreman.keyfile": None,
    "foreman.cafile": None,
}


def __virtual__():
    return __virtualname__ if HAS_LIBS else (False, "requests or urllib.parse lib not found")


def top(**kwargs):
    '''
    Rather simple replacement of foreman-salt plugin
    Fetch states from host array parameter: `salt_states`
    The host must have parameter: `salt_master` equal to master_tops configured `master`
    The host must be placed within `master_tops` configured `location`
    Location must have `saltenv` parameter
    '''
    url = __opts__["foreman.url"]
    user = __opts__["foreman.user"]
    password = __opts__["foreman.password"]
    verify = __opts__["foreman.verifyssl"]
    certfile = __opts__["foreman.certfile"]
    keyfile = __opts__["foreman.keyfile"]
    cafile = __opts__["foreman.cafile"]
    location = __opts__['master_tops'][__virtualname__]['location']
    salt_master_host = __opts__['master_tops'][__virtualname__]['master']
    minion_id = kwargs['opts']['id']
    headers = {"accept": "version=2,application/json"}  # Foreman API version 2 is supported

    def req(path):
        r = requests.get(
            "{}/{}".format(url, path),
            auth=(user, password),
            headers=headers,
            verify=verify,
            cert=(certfile, keyfile),
        )
        log.debug("HTTP response for: {}, is: {}".format(path, r))
        if r.status_code != 200:
            raise ValueError("Unable to fetch: {}".format(path))
        else:
            return r.json()

    def extract(path, key, default=None):
        j = req(path)
        return next(map(lambda r: r[key], j['results']), default)

    try:
        if verify and cafile is not None:
            verify = cafile

        loc_id = extract("locations?" + urllib.parse.quote("search={}".format(location)), 'id')
        if loc_id is None:
            raise ValueError("Location: {} not found".format(location))

        saltenv = extract("locations/{}/parameters?search=saltenv".format(loc_id), 'value', 'base')
        host_id = extract("hosts?" + urllib.parse.quote("search=location_id={} and name={} and params.salt_master={}".format(loc_id, minion_id, salt_master_host)), 'id', None)
        # mind that it is impossible to specify minionIDs in ext_nodes
        top = extract("locations/{}/parameters?search=top.sls".format(loc_id), 'value', {saltenv: {}})

        if host_id:
            host_salt_states = extract("hosts/{}/parameters?search=salt_states".format(host_id), 'value', [])
            if host_salt_states:
                top[saltenv] = host_salt_states
        log.info("top.sls created: %s", top)
        return top
    except Exception:  # pylint: disable=broad-except
        log.exception("Could not fetch host top.sls data via Foreman API:")
        return {}
