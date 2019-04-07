import os


def _set_permissions(path, user, home_dir):
    __salt__['file.chown'](path, user, user)
    while os.path.normpath(os.path.join(path, os.pardir)) != home_dir:
        path = os.path.normpath(os.path.join(path, os.pardir))
        __salt__['file.chown'](path, user, user)


def for_all(source_path, username, dest_path, files, override=False, saltenv='base'):
    result = []
    kwargs = {'salt': __salt__, 'pillar': __pillar__, 'grains': __grains__, 'opts': __opts__, 'username': username}
    for file_path in files:
        destination_path = file_path.replace(source_path, dest_path)

        result_file = None
        if not os.path.isfile(destination_path) or override:
            if __opts__['test']:
                result_file = destination_path
            else:
                result_file = __salt__['cp.get_template']("{0}".format(file_path), destination_path,
                                                          makedirs=True, saltenv=saltenv, **kwargs)

        if result_file:
            if not __opts__['test']:
                _set_permissions(result_file, username, dest_path)
            result.append(result_file)
    return result
