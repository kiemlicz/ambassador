from __future__ import absolute_import, print_function, unicode_literals

import logging
import importlib
log = logging.getLogger(__name__)

try:
    import gdrive
    from google.oauth2.credentials import Credentials
    from salt.ext.six.moves.urllib.parse import urlparse, parse_qs

    HAS_GOOGLE_LIBS = True
except ImportError:
    HAS_GOOGLE_LIBS = False


def __virtual__():
    return HAS_GOOGLE_LIBS


def has_libs():
    return __virtual__()


def client(profile):
    credentials = Credentials(token=profile['access_token'],
                              refresh_token=profile['refresh_token'],
                              token_uri=profile['token_url'],
                              client_id=profile['client_id'],
                              client_secret=profile['client_secret'])
    auth = gdrive.GoogleAuth(credentials)
    log.debug("building drive service for client: {}".format(profile['client_id']))
    return gdrive.GDriveClient(auth)
