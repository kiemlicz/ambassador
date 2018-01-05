import logging

import salt.cache
import salt.client
import salt.syspaths as syspaths

log = logging.getLogger(__name__)


def check(triggering_minion, expected_minions_list, action_type):
    bank = "{}_finished".format(action_type)
    cache = salt.cache.Cache(__opts__, syspaths.CACHE_DIR)
    cache.store(bank, triggering_minion, "ok")
    finished_minions_list = cache.list(bank)

    log.debug("Triggering minion: {}, completed minions: {}, expected: {}"
              .format(triggering_minion, finished_minions_list, expected_minions_list))

    if len(finished_minions_list) == len(expected_minions_list) and \
            sorted(finished_minions_list) == sorted(expected_minions_list):
        cache.flush(bank)
        __salt__['event.send']('salt/{}/ret'.format(action_type), {
            'minions': expected_minions_list,
        })
