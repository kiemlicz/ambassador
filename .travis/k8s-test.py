from __future__ import print_function

import unittest
import testinfra
import logging
import sys
import json
import yaml
import time
import re
from kubernetes import client, config
from functools import wraps
from deepdiff import DeepDiff


def retry(ExceptionToCheck, tries=4, delay=3, backoff=2, logger=None):
    """Retry calling the decorated function using an exponential backoff.

    http://www.saltycrane.com/blog/2009/11/trying-out-retry-decorator-python/
    original from: http://wiki.python.org/moin/PythonDecoratorLibrary#Retry

    :param ExceptionToCheck: the exception to check. may be a tuple of
        exceptions to check
    :type ExceptionToCheck: Exception or tuple
    :param tries: number of times to try (not retry) before giving up
    :type tries: int
    :param delay: initial delay between retries in seconds
    :type delay: int
    :param backoff: backoff multiplier e.g. value of 2 will double the delay
        each retry
    :type backoff: int
    :param logger: logger to use. If None, print
    :type logger: logging.Logger instance
    """
    def deco_retry(f):
        @wraps(f)
        def f_retry(*args, **kwargs):
            mtries, mdelay = tries, delay
            while mtries > 1:
                try:
                    return f(*args, **kwargs)
                except ExceptionToCheck as e:
                    log.warning("%s, Retrying in %d seconds..." % (str(e), mdelay))
                    time.sleep(mdelay)
                    mtries -= 1
                    mdelay *= backoff
            return f(*args, **kwargs)
        return f_retry  # true decorator

    return deco_retry


class KubectlSaltBackend(object):
    def __init__(self, kubectlBackend):
        self.kubectl = kubectlBackend

    def _invoke_salt(self, cmd):
        output = self.run(cmd)
        if output.stderr:
            log.error("The command: {}, stderr: {}".format(cmd, output.stderr))
        return output

    def _loads(self, stdout):
        log.debug("Loading: {}".format(stdout))
        # todo this is not the best approach
        # stdout may be polluted with salt's print statements (like 'No return')
        # thus the loads(...) will fail as stdout contains not only the JSON
        try:
            return json.loads(stdout)
        except json.decoder.JSONDecodeError as e:
            log.error("Unable to parse output: {}".format(stdout))
            log.exception(e)
            return {}

    def run(self, cmd):
        return self.kubectl.run(cmd)

    def runner(self, runner_fun):
        output = self._invoke_salt("salt-run --out=json -l error {}".format(runner_fun))
        return self._loads(output.stdout)

    def local(self, local_fun):
        output = self._invoke_salt("salt --out json -l error {}".format(local_fun))
        return self._loads(output.stdout)

    def caller(self, caller_fun):
        output = self._invoke_salt("salt-call --local --out json -l error {}".format(caller_fun))
        return self._loads(output.stdout)


# todo add random POD failure tests
class SaltDeploymentTest(unittest.TestCase):
    minion_count = 1

    def setUp(self) -> None:
        self.masters = [e.metadata.name for e in coreV1.list_namespaced_pod(namespace=namespace, label_selector="app=salt,role=master").items]
        self.minions = [e.metadata.name for e in coreV1.list_namespaced_pod(namespace=namespace, label_selector="app=salt,role=minion").items]
        if not self.masters:
            self.fail("No Salt Master instances found in namespace: {}".format(namespace))
        self.saltMaster = KubectlSaltBackend(testinfra.get_host("kubectl://{}?namespace={}".format(next(iter(self.masters)), namespace)))
        self.startTime = time.time()

    def tearDown(self) -> None:
        t = time.time() - self.startTime
        print("%s: %.3f" % (self.id(), t))

    def test_01_minion_delete(self):
        # given
        old_minions = self.minions
        for m in old_minions:
            coreV1.delete_namespaced_pod(name=m, namespace=namespace)

        # when
        time.sleep(10)

        # then
        self.assert_connected_minions()
        new_minions = [e.metadata.name for e in coreV1.list_namespaced_pod(namespace=namespace, label_selector="app=salt,role=minion").items]
        self.assertEqual(len(set(old_minions) & set(new_minions)), 0)  # all new minions

    # fixme the master restart causes existing minions not to connect
    def test_02_master_delete(self):
        # given
        old_masters = self.masters
        for m in old_masters:
            coreV1.delete_namespaced_pod(name=m, namespace=namespace)

        # when
        time.sleep(10)

        # then
        self.assert_connected_minions()
        new_masters = [e.metadata.name for e in coreV1.list_namespaced_pod(namespace=namespace, label_selector="app=salt,role=master").items]
        self.assertEqual(len(set(old_masters) & set(new_masters)), 0)  # all new masters

    @retry(Exception, delay=20)
    def assert_connected_minions(self):
        # given
        masters = [e.metadata.name for e in coreV1.list_namespaced_pod(namespace=namespace, label_selector="app=salt,role=master").items]

        if not masters:
            self.fail("No Salt Master instances found in namespace: {} (in repeatable assertion)".format(namespace))
        master = KubectlSaltBackend(testinfra.get_host("kubectl://{}?namespace={}".format(next(iter(masters)), namespace)))

        # when
        minions_json = master.runner("manage.up")

        # then
        self.assertEqual(len(minions_json), SaltDeploymentTest.minion_count)
        pong = master.local("'*' test.version")
        self.assertEqual(len(pong), SaltDeploymentTest.minion_count, "Wrong PONG response: {}".format(pong))


class SaltK8sEngineTest(unittest.TestCase):
    test_namespace = "salt-provisioning-test"

    def setUp(self) -> None:
        self.masters = [e.metadata.name for e in coreV1.list_namespaced_pod(namespace=namespace, label_selector="app=salt,role=master").items]
        self.minions = [e.metadata.name for e in coreV1.list_namespaced_pod(namespace=namespace, label_selector="app=salt,role=minion").items]
        if not self.masters:
            self.fail("No Salt Master instances found in namespace: {}".format(namespace))
        self.saltMaster = KubectlSaltBackend(testinfra.get_host("kubectl://{}?namespace={}".format(next(iter(self.masters)), namespace)))
        ns = client.V1Namespace(metadata=client.V1ObjectMeta(name=SaltK8sEngineTest.test_namespace))
        coreV1.create_namespace(body=ns)
        with open(".travis/k8s-test-deployment.yaml", 'r') as f:
            self.deployment_yaml = yaml.safe_load(f)

    def tearDown(self) -> None:
        coreV1.delete_namespace(name=SaltK8sEngineTest.test_namespace)

    def test_01_k8s_events(self):
        # given
        appsV1.create_namespaced_deployment(namespace=SaltK8sEngineTest.test_namespace, body=self.deployment_yaml)

        # when
        time.sleep(30)

        # then
        try:
            k8s_events = []
            # fixme this file will contain all k8s events from given namespace
            o = self.saltMaster.run("cat /var/log/salt/events")
            j = [json.loads(e) for e in o.stdout.splitlines()]
            k8s_events = [e for e in j if k8s_events_tag.match(e['tag'])]
            add_events = [e for e in k8s_events if e['tag'] == 'salt/engines/k8s_events/ADDED']
            mod_events = [e for e in k8s_events if e['tag'] == 'salt/engines/k8s_events/MODIFIED']
            self.assertEqual(len(add_events), 2)
            self.assertEqual(len(mod_events), 6)
            pods = {}
            for e in mod_events:
                pods.setdefault(e['data']['object']['metadata']['name'], []).append(e['data'])

            for k, v in pods.items():
                if len(v) > 1:
                    for e in v[1:]:
                        diff = DeepDiff(v[0], v[1])
                        log.info("DIFF: {}".format(pp.pformat(diff)))
                else:
                    log.info("no diff")
        except Exception as e:
            log.error("Cannot assert k8s_events, all events: \n{}".format(k8s_events))
            log.exception(e)
            raise e


log = logging.getLogger("k8s-test")
logging.basicConfig(stream=sys.stderr, level=logging.INFO)

pp = pprint.PrettyPrinter(indent=4)

# minikube sets KUBECONFIG properly
config.load_kube_config()
coreV1 = client.CoreV1Api()
appsV1 = client.AppsV1Api()
namespace = "salt-provisioning"

k8s_events_tag = re.compile("salt/engines/k8s_events/\S+")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        namespace = sys.argv.pop()
        log.info("Changed namespace to: {}".format(namespace))
    unittest.main(verbosity=2)
