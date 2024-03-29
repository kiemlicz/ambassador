import logging
import os
from salt.exceptions import CommandExecutionError


def managed(name, download_url, destination_dir, user, group, enforce_toplevel=True, saltenv='base', **kwargs):
    '''
    Wrapper for archive.extracted
    Adds symlink to 'name' location
    '''
    ret = {'name': name, 'changes': {}, 'result': False, 'comment': ''}
    log = logging.getLogger(__name__)

    # listing before extraction as archive.extracted has bug and requires to pass enforce_ownership_on:
    # https://github.com/saltstack/salt/issues/38605
    try:
        archive_contents = __salt__['archive.list'](download_url)
    except CommandExecutionError as e:
        location = __salt__['cp.is_cached'](download_url)
        if location:
            location_parent = __salt__['file.dirname'](location)
            log.error("unable to list archive ({}) clearing cache: {}".format(download_url, location_parent))
            result = __salt__['file.remove'](location_parent)
            log.error("Cache clear result: {}".format(result))
        else:
            log.error("Unable to clear cache, bogus cached file: {}".format(location))
        return __utils__['common.fail'](ret, "devtool: failed to list archive ({}), error:".format(download_url, str(e)))

    extract_dir = os.path.commonprefix(archive_contents)  # relative path
    log.info("Extract to directory: %s", extract_dir)

    if not extract_dir or extract_dir == "./":
        if not enforce_toplevel:
            return __utils__['common.fail'](ret, "devtool: Cannot find root directory in extracted archive, try setting enforce_toplevel: True", comments=archive_contents)
        else:
            kwargs['enforce_toplevel'] = True
    extract_location = os.path.join(destination_dir, extract_dir)
    log.debug("Will extract to: {0}".format(extract_location))

    # since 2016.11 archive_format is no longer needed

    # todo check if user/group may be left for windows or will cause failure
    extract_result = __states__['archive.extracted'](name=destination_dir, source=download_url, user=user, group=group,
                                                     enforce_ownership_on=extract_location, skip_verify=True, enforce_toplevel=enforce_toplevel,
                                                     trim_output=50, **kwargs)
    if not extract_result['result']:
        return __utils__['common.fail'](ret, "devtool: cannot extract archive from: {0}".format(download_url), comments=[extract_result['comment']])

    old_state = ["{0} previously didn't exist".format(download_url)]
    if not extract_result['changes']:
        # was already downloaded
        old_state = ["{0} was already extracted in {1}\n".format(download_url, destination_dir)]

    symlink_result = __states__['file.symlink'](name=name, target=extract_location, user=user)
    if not symlink_result['result']:
        return __utils__['common.fail'](ret, "devtool: Cannot create symlink ({0}) to: {1}".format(name, extract_location))

    ret['changes'].update({'devtool': {
        'old': old_state,
        'new': ["Extracted to: {0}".format(extract_location)]
    }})
    return __utils__['common.success'](ret, "DEVTOOL: success")
