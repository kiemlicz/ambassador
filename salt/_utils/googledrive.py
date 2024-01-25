from __future__ import absolute_import, print_function, unicode_literals

import logging

log = logging.getLogger(__name__)

try:
    from gdrive import GoogleAuth, GDriveClient

    HAS_GOOGLE_LIBS = True
except ImportError:
    log.exception("Cannot import gdrive pip library")
    HAS_GOOGLE_LIBS = False


def __virtual__():
    return HAS_GOOGLE_LIBS


def has_libs():
    return __virtual__()


def client(profile):
    auth = GoogleAuth.from_settings(
        profile['token_file'],
        profile['secrets'],
        profile['scopes'],
    )
    log.debug(f"Building Google drive service (secrets location: {profile['secrets']}")
    return GDriveClient(auth)
