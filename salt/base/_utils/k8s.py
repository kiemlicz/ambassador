from __future__ import absolute_import, print_function, unicode_literals

import logging
import os

from salt.exceptions import CommandExecutionError

try:
    from kubernetes import client, config, watch
    from kubernetes.client import ApiClient
    from kubernetes.client.rest import ApiException

    HAS_K8S = True
except ImportError:
    HAS_K8S = False


log = logging.getLogger(__name__)


def __virtual__():
    return HAS_K8S


def has_libs():
    return __virtual__()


class K8sClient(object):
    def __init__(self, **kwargs):
        # todo don't assert this in constructor, expose this information via dedicated function
        if not HAS_K8S:
            raise CommandExecutionError('(unable to import kubernetes, module most likely not installed)')

        self.active_namespace = "default"

        if "KUBERNETES_SERVICE_HOST" in os.environ:
            log.debug("K8s loading incluster config")
            config.load_incluster_config()
            with open("/var/run/secrets/kubernetes.io/serviceaccount/namespace", "r") as f:
                self.active_namespace = f.read()
        else:
            log.debug("K8s loading config")
            try:
                config.load_kube_config(**kwargs)
            except FileNotFoundError as e:
                raise CommandExecutionError("unable to create kubernetes config: {}".format(e))

        self.client_apps_v1_api = client.AppsV1Api()
        self.client_core_v1_api = client.CoreV1Api()
        self.client_api = ApiClient()
        self.watch = watch.Watch()

    def read(self, kind, namespaced=True, name=None, namespace=None):
        if not namespace:
            namespace = self.active_namespace
        method = "read_namespaced_{}".format(kind) if namespaced else "read_{}".format(kind)
        return self._invoke(kind, method, namespaced, name=name, namespace=namespace)

    def list(self, kind, namespaced=True, label_selector=None, namespace=None):
        if not namespace:
            namespace = self.active_namespace
        method = self._list(kind, namespaced)
        return self._invoke(kind, method, namespaced, label_selector=label_selector, namespace=namespace)

    def _list(self, kind, namespaced=True):
        return "list_namespaced_{}".format(kind) if namespaced else "list_{}".format(kind)

    # use _request_timeout to stop the watch after given time
    def watch_start(self, kind, namespaced=True, **kwargs):
        func = self._get_func(kind, self._list(kind, namespaced))
        return self.watch.stream(func, **kwargs)

    def watch_stop(self):
        self.watch.stop()

    def _invoke(self, kind, method, namespaced, **kwargs):
        try:
            if not namespaced:
                kwargs.pop('namespace')
            result = self._get_func(kind, method)(**kwargs)
            return self.sanitize_for_serialization(result)
        except ApiException as e:
            log.error("unable to fetch: {}".format(kind))
            log.exception(e)
            return None

    def sanitize_for_serialization(self, e):
        return self.client_api.sanitize_for_serialization(e)

    def _get_func(self, kind, method):
        try:
            c = self._client(kind)
            return getattr(c, method)
        except AttributeError as e:
            log.exception(e)
            raise CommandExecutionError("Method {} not found".format(method))

    def _client(self, kind):
        if kind == "pod" or kind == "persistent_volume" or kind == "persistent_volume_claim" or kind == "namespace":
            return self.client_core_v1_api
        else:
            return self.client_apps_v1_api


def k8s_client(**kwargs):
    log.info("Creating K8s client")
    return K8sClient(**kwargs)
