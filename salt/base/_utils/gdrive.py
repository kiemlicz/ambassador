from __future__ import absolute_import, print_function, unicode_literals

import logging

try:
    from google.oauth2.credentials import Credentials
    from googleapiclient.discovery import build
    from salt.ext.six.moves.urllib.parse import urlparse, parse_qs
    import gdrive

    HAS_GOOGLE_LIBS = True
except ImportError:
    HAS_GOOGLE_LIBS = False

log = logging.getLogger(__name__)


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
    auth = gdrive.auth.GoogleAuth(credentials)
    log.debug("building drive service for client: {}".format(profile['client_id']))
    return gdrive.client.GDriveClient(auth)
