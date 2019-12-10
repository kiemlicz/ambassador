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


# todo add POD failure tests
# todo add k8s_events engine tests
class SaltMasterTest(unittest.TestCase):
    minion_count = 1

    def setUp(self) -> None:
        self.masters = [e.metadata.name for e in coreV1.list_namespaced_pod(namespace=namespace, label_selector="app=salt,role=master").items]
        self.minions = [e.metadata.name for e in coreV1.list_namespaced_pod(namespace=namespace, label_selector="app=salt,role=minion").items]
        if not self.masters:
            self.fail("No Salt Master instances found in namespace: {}".format(namespace))
        self.saltMaster = KubectlSaltBackend(testinfra.get_host("kubectl://{}?namespace={}".format(next(iter(self.masters)), namespace)))

    @retry(Exception, tries=5)
    def assert_connected_minions(self):
        # given
        self.setUp()
        minions_json = self.saltMaster.runner("manage.up")
        # then
        self.assertEqual(len(minions_json), SaltMasterTest.minion_count)
        pong = self.saltMaster.local("'*' test.ping")
        self.assertEqual(len(pong), SaltMasterTest.minion_count, "Wrong PONG response: {}".format(pong))

    def test_01_minion_delete(self):
        # given
        old_minions = self.minions
        for m in old_minions:
            coreV1.delete_namespaced_pod(name=m, namespace=namespace)

        # when
        time.sleep(10)

        # then
        self.assert_connected_minions()
        new_minions = self.minions
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
        new_masters = self.masters
        self.assertEqual(len(set(old_masters) & set(new_masters)), 0)  # all new masters

    def test_03_k8s_events(self):
        # given
        with open(".travis/k8s-test-deployment.yaml", 'r') as f:
            body = yaml.safe_load(f)
            appsV1.create_namespaced_deployment(namespace=namespace, body=body)

        # when
        time.sleep(10)

        # then
        try:
            o = self.saltMaster.run("cat /var/log/salt/events")
            log.error(" stdout -> {}".format(o.stdout))
            j = json.loads(o.stdout)
            log.error(" -> {}".format(j))
            k8s_events = [e for e in j if k8s_events_tag.match(e['tag'])]
            log.error(" k8sevents only -> {}".format(k8s_events))
        except Exception as e:
            log.error("Cannot assert k8s_events")
            log.exception(e)
            raise e


log = logging.getLogger("k8s-test")
logging.basicConfig(stream=sys.stderr, level=logging.INFO)

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
