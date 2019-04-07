import logging

log = logging.getLogger(__name__)


def send_when(tag, data, condition=False):
    if condition:
        log.debug("Sending event: {}".format(tag))
        __salt__['event.send'](tag, data)
    else:
        log.debug("Condition is not met")
