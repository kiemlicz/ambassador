import logging
import os
import posixpath

import salt.config
import salt.utils.data
import salt.version
from salt.ext import six
from salt.ext.six.moves.urllib.parse import urlparse


log = logging.getLogger(__name__)


def __virtual__():
    return True if __utils__['gdrive.has_libs']() else (False, "Cannot load file.ext, install: pyasn1-modules and google-auth-oauthlib libraries")


def managed(name, source=None, contents=None, **kwargs):
    '''
    State that extends file.managed with new source scheme (`gdrive://`)
    If other than `gdrive://` scheme is used, execution is delegated to `file.managed` state

    If the specified `source` path is ambiguous (on gdrive you can store multiple folders with same name)
    then the returned result is undefined (will fetch any of ambiguous folders/files)
    In order to use this state you must pre-authorize file_ext in your google drive using file_ext_authorize

    Also set pillar_opts: True in master config file
    '''

    def delegate_to_file_managed(source, contents):
        log.info("Propagating to file.managed (source: {})".format(source))
        return __states__['file.managed'](name, source=source, contents=contents, **kwargs)

    if not source:
        return delegate_to_file_managed(source, contents)
    source = salt.utils.data.decode(source)
    if urlparse(source).scheme != 'gdrive':
        return delegate_to_file_managed(source, contents)

    gdrive = _get_client()
    contents = gdrive.get_file_contents(source)
    return delegate_to_file_managed(source=None, contents=contents)


def recurse(name,
            source,
            clean=False,
            replace=True,
            include_pat=None,
            exclude_pat=None,
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
        return __states__['file.recurse'](name, source=source, **kwargs)

    def delegate_to_file_managed(path, contents, replace):
        return __states__['file.managed'](path, source=None, makedirs=True, replace=replace, contents=contents, **kwargs)

    def delegate_to_file_directory(path):
        return __states__['file.directory'](path, recurse=[], makedirs=True, clean=False, require=None, **kwargs)

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
                _ret['changes'] = {'diff': 'Replaced directory with a new file'}
                merge_ret(path, _ret)

        try:
            c = gdrive.get_file(file_meta)
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

    source = salt.utils.data.decode(source)
    if urlparse(source).scheme != 'gdrive':
        return delegate_to_file_recurse()

    if not source.endswith(posixpath.sep):
        source = source + posixpath.sep

    gdrive = _get_client()
    dir_hierarchy = gdrive.walk(source, include_pat, exclude_pat, source)
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


def _get_client():
    profile = __salt__['config.get']('gdrive', merge="recurse")
    return __utils__['gdrive.client'](profile)
