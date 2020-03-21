import unittest
import testinfra
import logging
import sys
import json
import time
import pprint
from kubernetes import client, config
from retrying import retry


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
        log.info("%s: %.3f", self.id(), t)

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

    @retry(retry_on_exception=lambda e: isinstance(e, Exception), stop_max_delay=300000, wait_exponential_max=10000)  # 5min deadline
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


logging.basicConfig(stream=sys.stderr, level=logging.INFO)
log = logging.getLogger("k8s-test")
pp = pprint.PrettyPrinter(indent=4)

config.load_kube_config()
coreV1 = client.CoreV1Api()
appsV1 = client.AppsV1Api()
namespace = "salt-provisioning"

if __name__ == "__main__":
    if len(sys.argv) > 1:
        namespace = sys.argv.pop()
        log.info("Changed namespace to: {}".format(namespace))
    unittest.main(verbosity=1)
