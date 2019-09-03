# -*- coding: utf-8 -*-
'''
Send events from Kubernetes
:Depends:   kubernetes
'''
# Import Python Libs
from __future__ import absolute_import, print_function, unicode_literals

from itertools import chain

import logging
import queue
import threading

import salt.utils.json
import salt.utils.event


log = logging.getLogger(__name__)

CLIENT_TIMEOUT = 60

__virtualname__ = 'k8s_events'


def __virtual__():
    return True


def start(timeout=CLIENT_TIMEOUT,
          tag='salt/engines/k8s_events',
          watch_defs=None):
    c = _get_client()

    if __opts__.get('__role') == 'master':
        fire_master = salt.utils.event.get_master_event(
            __opts__,
            __opts__['sock_dir']).fire_event
    else:
        fire_master = None

    def multiplex(generators):
        if len(generators) > 1:
            # multiplex only when needed
            q = queue.Queue()

            def run_one(src):
                for e in src: q.put(e)

            def run_all():
                threads = []
                for src in generators:
                    t = threading.Thread(target=run_one, args=(src,))
                    t.start()
                    threads.append(t)
                for t in threads: t.join()
                q.put(StopIteration)

            threading.Thread(target=run_all).start()

            while True:
                e = q.get()
                if e is StopIteration: return
                yield e
        elif len(generators) == 1:
            return generators[0]
        else:
            return []

    def fire(tag, msg):
        '''
        How to fire the event
        '''
        if fire_master:
            fire_master(msg, tag)
        else:
            __salt__['event.send'](tag, msg)

    try:
        all_watch = [(c.sanitize_for_serialization(e) for e in c.watch_start(watch_def.pop('kind'), **watch_def)) for watch_def in watch_defs]
        for event in multiplex(all_watch):
            fire('{0}/{1}'.format(tag, event['type']), event)
    except Exception as e:
        log.error("Unable to watch() k8s resources")
        log.exception(e)
        c.watch_stop()


def _get_client(profile=None):
    return __utils__['k8s.k8s_client'](profile=profile)
