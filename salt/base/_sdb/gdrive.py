import logging

log = logging.getLogger(__name__)


def __virtual__():
    has_libs = __utils__['gdrive.has_libs']()
    if not has_libs:
        # somehow sdb modules doesn't print missing lib message nicely, instead you will just see KeyError 'kdbx.get'
        # that's why this additional log message
        log.error("pip3: google-api-python-client google-auth-httplib2 google-auth-oauthlib not found")
    return True if has_libs else (False, "google-api-python-client google-auth-httplib2 google-auth-oauthlib not found")


def get(key, profile=None):
    client = _get_client(profile)
    return client.get_file_plain_text(key)


def _get_client(profile):
    return __utils__['gdrive.client'](profile)
