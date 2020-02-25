from __future__ import absolute_import, print_function, unicode_literals

import logging
import os
from distutils.util import strtobool
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
                log.exception("KUBECONFIG file not found")
                raise CommandExecutionError("unable to create kubernetes config: {}".format(e)) from e

        self.client_apps_v1_api = client.AppsV1Api()
        self.client_core_v1_api = client.CoreV1Api()
        self.client_api = ApiClient()
        self.watch = watch.Watch()

    def read(self, kind, namespaced=True, name=None, namespace=None):
        if not namespace:
            namespace = self.active_namespace
        if not isinstance(namespaced, bool):
            namespaced = strtobool(namespaced)
        method = "read_namespaced_{}".format(kind) if namespaced else "read_{}".format(kind)
        return self._invoke(kind, method, namespaced, name=name, namespace=namespace)

    def list(self, kind, namespaced=True, label_selector=None, namespace=None, all_namespaces=False):
        if not namespace:
            namespace = self.active_namespace
        if not isinstance(namespaced, bool):
            namespaced = strtobool(namespaced)
        if not isinstance(all_namespaces, bool):
            all_namespaces = strtobool(all_namespaces)
        method = self._list(kind, namespaced, all_namespaces)
        return self._invoke(kind, method, namespaced, all_namespaces, label_selector=label_selector, namespace=namespace)

    def _list(self, kind, namespaced=True, all_namespaces=False):
        if all_namespaces:
            return "list_{}_for_all_namespaces".format(kind)
        return "list_namespaced_{}".format(kind) if namespaced else "list_{}".format(kind)

    # use _request_timeout to stop the watch after given time
    def watch_start(self, kind, namespaced=True, timeout=None, **kwargs):
        func = self._get_func(kind, self._list(kind, namespaced))
        if '_request_timeout' not in kwargs and timeout:
            kwargs['_request_timeout'] = timeout
        return self.watch.stream(func, **kwargs)

    def watch_stop(self):
        self.watch.stop()

    def _invoke(self, kind, method, namespaced, all_namespaces=False, **kwargs):
        try:
            if not namespaced or all_namespaces:
                kwargs.pop('namespace')
            result = self._get_func(kind, method)(**kwargs)
            return self.sanitize_for_serialization(result)
        except ApiException as e:
            log.exception("unable to fetch: %s", kind)
            return None

    def sanitize_for_serialization(self, e):
        return self.client_api.sanitize_for_serialization(e)

    def _get_func(self, kind, method):
        try:
            c = self._client(kind)
            return getattr(c, method)
        except AttributeError as e:
            log.exception(e)
            raise CommandExecutionError("Method {} not found".format(method)) from e

    def _client(self, kind):
        if kind == "pod" or kind == "persistent_volume" or kind == "persistent_volume_claim" or kind == "namespace":
            return self.client_core_v1_api
        else:
            return self.client_apps_v1_api


def k8s_client(**kwargs):
    log.info("Creating K8s client")
    return K8sClient(**kwargs)
