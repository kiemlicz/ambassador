from __future__ import absolute_import, division, print_function, unicode_literals
import salt.utils.stringutils


def last(name, add, match, stamp=False, prune=0):
    '''
    updates the specified values to the newest one

    If ``stamp`` is True, then the timestamp from the event will also be added
    if ``prune`` is set to an integer higher than ``0``, then only the latest
    ``prune`` values will be kept in the list.

    USAGE:

    .. code-block:: yaml

        foo:
          reg.list:
            - add: bar
            - match: my/custom/event
            - stamp: True
    '''
    ret = {'name': name,
           'changes': {},
           'comment': '',
           'result': True}

    if not isinstance(add, list):
        add = add.split(',')
    if name not in __reg__:
        __reg__[name] = {}
        __reg__[name]['val'] = []

    for event in __events__:
        try:
            event_data = event['data']['data']
        except KeyError:
            event_data = event['data']
        if salt.utils.stringutils.expr_match(event['tag'], match):
            item = {}
            for key in add:
                if key in event_data:
                    item[key] = event_data[key]
                    if stamp is True:
                        item['time'] = event['data']['_stamp']
            __reg__[name]['val'].append(item)
    if prune > 0:
        __reg__[name]['val'] = __reg__[name]['val'][-prune:]
    return ret
