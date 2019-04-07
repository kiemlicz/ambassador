# -*- coding: utf-8 -*-
'''
Send events from Kubernetes
:Depends:   kubernetes
'''

import logging


log = logging.getLogger(__name__)


def __virtual__():
    return True


def start():
    pass


def _get_client(profile=None):
    return __utils__['k8s.k8s_client'](profile=profile)
