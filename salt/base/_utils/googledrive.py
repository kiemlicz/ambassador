from __future__ import absolute_import, print_function, unicode_literals

import logging
log = logging.getLogger(__name__)

try:
    import requests_oauthlib
    '''
    Without this and without upgrading pip:
    [ERROR   ] Failed to import utils googledrive, this is due most likely to a syntax error:
Traceback (most recent call last):
  File "/usr/lib/python3/dist-packages/salt/loader.py", line 1707, in _load_module
    mod = spec.loader.load_module()
  File "<frozen importlib._bootstrap_external>", line 407, in _check_name_wrapper
  File "<frozen importlib._bootstrap_external>", line 907, in load_module
  File "<frozen importlib._bootstrap_external>", line 732, in load_module
  File "<frozen importlib._bootstrap>", line 262, in _load_module_shim
  File "<frozen importlib._bootstrap>", line 630, in _exec
  File "<frozen importlib._bootstrap_external>", line 728, in exec_module
  File "<frozen importlib._bootstrap>", line 219, in _call_with_frames_removed
  File "/var/cache/salt/minion/extmods/utils/googledrive.py", line 10, in <module>
    import gdrive
  File "/usr/local/lib/python3.7/dist-packages/gdrive/__init__.py", line 1, in <module>
    from .auth import GoogleAuth
  File "/usr/local/lib/python3.7/dist-packages/gdrive/auth.py", line 10, in <module>
    from google_auth_oauthlib.flow import InstalledAppFlow
  File "/usr/local/lib/python3.7/dist-packages/google_auth_oauthlib/__init__.py", line 21, in <module>
    from .interactive import get_user_credentials
  File "/usr/local/lib/python3.7/dist-packages/google_auth_oauthlib/interactive.py", line 24, in <module>
    import google_auth_oauthlib.flow
  File "/usr/local/lib/python3.7/dist-packages/google_auth_oauthlib/flow.py", line 72, in <module>
    import google_auth_oauthlib.helpers
  File "/usr/local/lib/python3.7/dist-packages/google_auth_oauthlib/helpers.py", line 28, in <module>
    import requests_oauthlib
  File "/usr/local/lib/python3.7/dist-packages/requests_oauthlib/__init__.py", line 12, in <module>
    if requests.__version__ < "2.0.0":
TypeError: '<' not supported between instances of 'module' and 'str'
    '''
    import gdrive
    from google.oauth2.credentials import Credentials
    from salt.ext.six.moves.urllib.parse import urlparse, parse_qs

    HAS_GOOGLE_LIBS = True
except ImportError:
    log.exception("GDRIVE FAIL")
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
