# -*- coding: utf-8 -*-
'''
Send events from Kubernetes
:Depends:   kubernetes
'''
# Import Python Libs
from __future__ import absolute_import, print_function, unicode_literals

from itertools import chain

import logging

import salt.utils.json
import salt.utils.event


log = logging.getLogger(__name__)

CLIENT_TIMEOUT = 60

__virtualname__ = 'k8s_events'


def __virtual__():
    return True


def start(timeout=CLIENT_TIMEOUT,
          tag='salt/engines/k8s_events',
          namespaces=None):
    c = _get_client()

    if __opts__.get('__role') == 'master':
        fire_master = salt.utils.event.get_master_event(
            __opts__,
            __opts__['sock_dir']).fire_event
    else:
        fire_master = None

    def fire(tag, msg):
        '''
        How to fire the event
        '''
        if fire_master:
            fire_master(msg, tag)
        else:
            __salt__['event.send'](tag, msg)

    try:
        aggregate_generator = chain([c.watch_start(namespace, timeout) for namespace in namespaces])
        for event in aggregate_generator:
            data = salt.utils.json.loads(event.decode(__salt_system_encoding__, errors='replace'))
            if data['Action']:
                fire('{0}/{1}'.format(tag, data['Action']), data)
            else:
                fire('{0}/{1}'.format(tag, data['status']), data)
    except Exception as e:
        log.error("Unable to watch() k8s resources")
        log.exception(e)
        c.watch_stop()


def _get_client(profile=None):
    return __utils__['k8s.k8s_client'](profile=profile)
