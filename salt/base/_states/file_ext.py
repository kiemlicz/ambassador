import json
import logging
import os
import posixpath

import salt.config
import salt.utils.locales
import salt.version
from salt.exceptions import CommandExecutionError
from salt.ext import six
from salt.ext.six.moves.urllib.parse import urlparse

try:
    from google.auth.transport.urllib3 import AuthorizedHttp
    from google.oauth2.credentials import Credentials

    HAS_GOOGLE_AUTH = True
except ImportError:
    HAS_GOOGLE_AUTH = False

log = logging.getLogger(__name__)


def __virtual__():
    salt_version = salt.version.__saltstack_version__.string
    supported = ["2019.2.0"]
    if salt_version not in supported:
        return False, "Cannot load file.ext, install: salt version {} (detected: {})".format(supported, salt_version)
    return True if HAS_GOOGLE_AUTH else (False, "Cannot load file.ext, install: google-auth, pyasn1-modules and google-auth-oauthlib libraries")


def managed(name,
            source=None,
            source_hash='',
            source_hash_name=None,
            keep_source=True,
            user=None,
            group=None,
            mode=None,
            attrs=None,
            template=None,
            makedirs=False,
            dir_mode=None,
            context=None,
            replace=True,
            defaults=None,
            backup='',
            show_changes=True,
            create=True,
            contents=None,
            tmp_dir='',
            tmp_ext='',
            contents_pillar=None,
            contents_grains=None,
            contents_newline=True,
            contents_delimiter=':',
            encoding=None,
            encoding_errors='strict',
            allow_empty=True,
            follow_symlinks=True,
            check_cmd=None,
            skip_verify=False,
            win_owner=None,
            win_perms=None,
            win_deny_perms=None,
            win_inheritance=True,
            win_perms_reset=False,
            **kwargs):
    '''
    State that extends file.managed with new source scheme (`gdrive://`)
    If other than `gdrive://` scheme is used, execution is delegated to `file.managed` state

    If the specified `source` path is ambiguous (on gdrive you can store multiple folders with same name)
    then the returned result is undefined (will fetch any of ambiguous folders/files)
    In order to use this state you must pre-authorize file_ext in your google drive using file_ext_authorize

    This extensions requires (pip):
     - google-auth
    Also set pillar_opts: True in master config file
    '''

    def delegate_to_file_managed(source, contents):
        return __states__['file.managed'](name, source, source_hash, source_hash_name, keep_source, user, group, mode,
                                          attrs, template,
                                          makedirs, dir_mode, context, replace, defaults, backup, show_changes, create,
                                          contents, tmp_dir, tmp_ext, contents_pillar, contents_grains, contents_newline,
                                          contents_delimiter, encoding, encoding_errors, allow_empty, follow_symlinks,
                                          check_cmd, skip_verify,
                                          win_owner, win_perms, win_deny_perms, win_inheritance, win_perms_reset,
                                          **kwargs)

    if not source:
        return delegate_to_file_managed(source, contents)
    source = salt.utils.locales.sdecode(source)
    if urlparse(source).scheme != 'gdrive':
        return delegate_to_file_managed(source, contents)

    authorized_http = _gdrive_connection()
    location = _source_to_gdrive_location_list(source)
    log.debug("Asserting path: {}".format(location))
    contents = _get_file(authorized_http, _traverse_to(authorized_http, location))

    log.info("Propagating contents to file.managed: {}".format(contents))
    return delegate_to_file_managed(source=None, contents=contents)


def recurse(name,
            source,
            keep_source=True,
            clean=False,
            require=None,
            user=None,
            group=None,
            dir_mode=None,
            file_mode=None,
            sym_mode=None,
            template=None,
            context=None,
            replace=True,
            defaults=None,
            include_empty=False,
            backup='',
            include_pat=None,
            exclude_pat=None,
            maxdepth=None,
            keep_symlinks=False,
            force_symlinks=False,
            win_owner=None,
            win_perms=None,
            win_deny_perms=None,
            win_inheritance=True,
            **kwargs):
    '''
    State that extends file.recurse with new source scheme (`gdrive://`)
    If other than `gdrive://` scheme is used, execution is delegated to `file.recurse` state
    '''
    ret = {
        'name': name,
        'changes': {},
        'pchanges': {},
        'result': True,
        'comment': {}  # { path: [comment, ...] }
    }

    def delegate_to_file_recurse():
        return __states__['file.recurse'](name, source, keep_source, clean, require, user, group, dir_mode, file_mode,
                                          sym_mode,
                                          template, context, replace, defaults, include_empty, backup, include_pat,
                                          exclude_pat, maxdepth, keep_symlinks, force_symlinks, win_owner, win_perms,
                                          win_deny_perms, win_inheritance, **kwargs)

    def delegate_to_file_managed(path, contents, replace):
        return __states__['file.managed'](path,
                                          source=None,
                                          user=user,
                                          group=group,
                                          mode=file_mode,
                                          template=template,
                                          makedirs=True,
                                          replace=replace,
                                          defaults=defaults,
                                          backup=backup,
                                          contents=contents,
                                          **kwargs)

    def delegate_to_file_directory(path):
        return __states__['file.directory'](path,
                                            user=user,
                                            group=group,
                                            recurse=[],
                                            dir_mode=dir_mode,
                                            file_mode=file_mode,
                                            makedirs=True,
                                            clean=False,
                                            require=None)

    def add_comment(path, comment):
        comments = ret['comment'].setdefault(path, [])
        if isinstance(comment, six.string_types):
            comments.append(comment)
        else:
            comments.extend(comment)

    def merge_ret(path, _ret):
        # Use the most "negative" result code (out of True, None, False)
        if _ret['result'] is False or ret['result'] is True:
            ret['result'] = _ret['result']

        # Only include comments about files that changed
        if _ret['result'] is not True and _ret['comment']:
            add_comment(path, _ret['comment'])

        if _ret['changes']:
            ret['changes'][path] = _ret['changes']

    def manage_file(path, replace, file_meta):
        if clean and os.path.exists(path) and os.path.isdir(path) and replace:
            _ret = {'name': name, 'changes': {}, 'result': True, 'comment': ''}
            if __opts__['test']:
                _ret['comment'] = u'Replacing directory {0} with a ' \
                                  u'file'.format(path)
                _ret['result'] = None
                merge_ret(path, _ret)
                return
            else:
                __salt__['file.remove'](path)
                _ret['changes'] = {'diff': 'Replaced directory with a '
                                           'new file'}
                merge_ret(path, _ret)

        try:
            c = _get_file(authorized_http, file_meta)
            _ret = delegate_to_file_managed(path, c, replace)
        except Exception as e:
            _ret = {
                'name': name,
                'changes': {},
                'result': False,
                'comment': str(e)
            }
        merge_ret(path, _ret)

    def manage_directory(path):
        _ret = delegate_to_file_directory(path)
        merge_ret(path, _ret)

    source = salt.utils.locales.sdecode(source)
    if urlparse(source).scheme != 'gdrive':
        return delegate_to_file_recurse()

    if not source.endswith(posixpath.sep):
        source = source + posixpath.sep

    authorized_http = _gdrive_connection()
    location = _source_to_gdrive_location_list(source)
    source_meta = _traverse_to(authorized_http, location)
    dir_hierarchy = _walk_dir(authorized_http, source_meta, include_pat, exclude_pat, source, source)
    log.debug("google drive walk result: {}".format(dir_hierarchy))

    def handle(file_list, absolute_dest_path):
        manage_directory(absolute_dest_path)
        for f in file_list:
            dest = os.path.join(absolute_dest_path, f['name'])
            if 'content' in f:
                handle(f['content'], dest)
            else:
                manage_file(dest, replace, f)

    handle(dir_hierarchy, name)
    return ret


def _source_to_gdrive_location_list(source):
    source = urlparse(source)
    p = source.netloc + source.path
    return p.strip(os.sep).split(os.sep)


def _walk_dir(auth_http, start_meta, include_pat, exclude_pat, current_path, source_path):
    def merge(indict, cpath):
        indict.update({'content': loop(indict, os.path.join(cpath, indict['name']))})
        return indict

    def loop(current_file_meta, cpath):
        def f(file_meta):
            relpath = posixpath.relpath(os.path.join(cpath, file_meta['name']), source_path)
            return salt.utils.check_include_exclude(relpath, include_pat, exclude_pat)

        return [(merge(e, cpath) if e['mimeType'] == 'application/vnd.google-apps.folder' else e) for e in
                filter(f, _list_children(auth_http, current_file_meta))]

    return loop(start_meta, current_path)


def _traverse_to(auth_http, path_segment_list):
    '''
    Asserts that path_segment_list exists on the google drive

    :return: full file_meta of file/folder traversed to (the last one in the path_segment_list)
    '''

    def go(parent_meta, idx):
        if idx >= len(path_segment_list):
            return parent_meta
        next_name = path_segment_list[idx]
        file_list = _list_children(auth_http, parent_meta)
        r = [e for e in file_list if e['name'] == next_name]
        if len(r) > 0:
            # don't care if name occurred in other pages or already multiple times
            return go(r[0], idx + 1)
        raise ValueError('Unable to find name: {}, under directory with meta: {}'.format(next_name, parent_meta))

    if not path_segment_list:
        return {'id': 'root', 'mimeType': ''}
    else:
        return go({'id': 'root'}, 0)


def _list_children(auth_http, parent_meta):
    def query(extra_params=None):
        request_params = {
            'q': "'{}' in parents".format(parent_meta['id'])
        }
        if extra_params is not None:
            request_params.update(extra_params)
        r = json.loads(
            auth_http.request('GET', 'https://www.googleapis.com/drive/v3/files', fields=request_params).data)
        _assert_incomplete_search(r)
        return r

    json_response = query()
    ret_list = json_response['files']
    while 'nextPageToken' in json_response:
        log.debug("Fetching next page of files under: {}".format(parent_meta))
        json_response = query({'pageToken': json_response['nextPageToken']})
        ret_list.extend(json_response['files'])
    return ret_list


def _get_file(auth_http, file_meta, mime_type='text/plain'):
    def export_file(file_id, mime_type):
        log.debug("Exporting file id: {}".format(file_id))
        return _do_get('https://www.googleapis.com/drive/v3/files/{}/export'.format(file_id), {'mimeType': mime_type})

    def download_file(file_id):
        log.debug("Downloading file id: {}".format(file_id))
        return _do_get('https://www.googleapis.com/drive/v3/files/{}?alt=media'.format(file_id))

    def _do_get(url, params={}):
        response = auth_http.request('GET', url, fields=params)
        if response.status >= 400:
            raise CommandExecutionError('Unable to download file (url: {}), reason: {}'.format(url, response.data))
        return response.data

    if file_meta['mimeType'] == 'application/vnd.google-apps.document':
        return export_file(file_meta['id'], mime_type)
    else:
        return download_file(file_meta['id'])


def _gdrive_connection():
    config = __salt__['config.get']('google_api')
    token_url = config['token_url']
    client_id = config['client_id']
    client_secret = config['client_secret']
    token = __salt__['pillar.get']("gdrive")
    log.debug("Token retrieved: {}".format(token))

    if not isinstance(token, dict):
        raise CommandExecutionError('Improper token format, does the google token exist?')

    credentials = Credentials(token[u'access_token'],
                              refresh_token=token[u'refresh_token'],
                              token_uri=token_url,
                              client_id=client_id,
                              client_secret=client_secret)
    return AuthorizedHttp(credentials)


def _assert_incomplete_search(json_response):
    if json_response['incompleteSearch']:
        raise CommandExecutionError('google drive query ended due to incompleteSearch')
