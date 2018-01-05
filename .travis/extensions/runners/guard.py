import logging

import salt.cache
import salt.client
import salt.syspaths as syspaths

log = logging.getLogger(__name__)


def check(triggering_minion, expected_minions_list, type):
    # todo make this more generic and move to envoy
    cache = salt.cache.Cache(__opts__, syspaths.CACHE_DIR)
    cache.store("{}_finished".format(type), triggering_minion, "ok")
    completed_minions_list = cache.list("{}_finished".format(type))

    log.debug("Triggering minion: {}, completed minions: {}, expected: {}"
              .format(triggering_minion, completed_minions_list, expected_minions_list))

    if len(completed_minions_list) == len(expected_minions_list) and \
            sorted(completed_minions_list) == sorted(expected_minions_list):
        __salt__['event.send']('salt/{}/ret'.format(type), {
            'minions': expected_minions_list,
        })
