import unittest
import logging
import sys
import pprint
import salt.config
import salt.utils.event
import timeout_decorator

from itertools import islice
from salt.runner import RunnerClient
from salt.client import LocalClient
from kubernetes import client, config


class SaltK8sEngineTest(unittest.TestCase):
    test_namespace = "salt-provisioning-test"

    @classmethod
    def setUpClass(cls) -> None:
        ns = client.V1Namespace(metadata=client.V1ObjectMeta(name=SaltK8sEngineTest.test_namespace))
        coreV1.create_namespace(body=ns)

    @classmethod
    def tearDownClass(cls) -> None:
        coreV1.delete_namespace(name=SaltK8sEngineTest.test_namespace)

    def setUp(self) -> None:
        self.deployment = client.V1Deployment(
            metadata=client.V1ObjectMeta(
                name="k8s-test-nginx-deployment",
                namespace=SaltK8sEngineTest.test_namespace,
                labels={"app": "nginx"}
            ),
            spec=client.V1DeploymentSpec(
                replicas=2,
                selector=client.V1LabelSelector(
                    match_labels={"app": "nginx"}
                ),
                template=client.V1PodTemplateSpec(
                    metadata=client.V1ObjectMeta(
                        labels={"app": "nginx"}
                    ),
                    spec=client.V1PodSpec(
                        containers=[
                            client.V1Container(
                                name="nginx",
                                image="nginx:1.7.9"
                            )
                        ]
                    )
                )
            )
        )
        # with testinfra it is impossible to create runner client
        # use python API (not netapi)
        self.master_opts = salt.config.client_config('/etc/salt/master')
        self.runner = RunnerClient(self.master_opts)
        self.local = LocalClient()
        self.event_stream = salt.utils.event.get_event('master',
                                                       sock_dir=self.master_opts['sock_dir'],
                                                       transport=self.master_opts['transport'],
                                                       opts=self.master_opts)

    @timeout_decorator.timeout(120)
    def test_01_k8s_events_add(self):
        # given

        # when
        appsV1.create_namespaced_deployment(namespace=SaltK8sEngineTest.test_namespace, body=self.deployment)

        # then
        # gathering specific but interleaved events fails
        # this is why we gather by regex
        k8s_events = list(islice(self.event_stream.iter_events(tag='salt/engines/k8s_events/*', match_type='fnmatch'), 8))
        mod_events = [e for e in k8s_events if e['type'] == 'MODIFIED']
        add_events = [e for e in k8s_events if e['type'] == 'ADDED']
        self.assertEqual(len(k8s_events), 8)
        self.assertEqual(len(mod_events), 6)
        self.assertEqual(len(add_events), 2)

        pods = {}
        for e in mod_events:
            if 'object' not in e:
                self.fail("incomplete event: {}".format(e))
            pods.setdefault(e['object']['metadata']['name'], []).append(e)

        self.assertEqual(len(pods), 2, "There must be two Nginx PODs only")

        for k, v in pods.items():
            if len(v) > 1:
                last = v[-1:][0]
                self.assertEqual(last['object']['status']['phase'], "Running")
                self.assertRegex(last['object']['status']['hostIP'], "\d+\.\d+\.\d+\.\d+")
                self.assertRegex(last['object']['status']['podIP'], "\d+\.\d+\.\d+\.\d+")
            else:
                self.fail("no MODIFIED event received")

    @timeout_decorator.timeout(120)
    def test_02_k8s_events_mod(self):
        # given
        # deployment exists from previous test
        self.deployment.spec.replicas = 3

        # when
        appsV1.patch_namespaced_deployment(name=self.deployment.metadata.name, namespace=SaltK8sEngineTest.test_namespace, body=self.deployment)

        # then
        k8s_events = list(islice(self.event_stream.iter_events(tag='salt/engines/k8s_events/*', match_type='fnmatch'), 4))
        mod_events = [e for e in k8s_events if e['type'] == 'MODIFIED']
        add_events = [e for e in k8s_events if e['type'] == 'ADDED']
        self.assertEqual(len(k8s_events), 4)
        self.assertEqual(len(mod_events), 3)
        self.assertEqual(len(add_events), 1)

    @timeout_decorator.timeout(120)
    def test_03_k8s_events_del(self):
        # given
        # deployment exists from previous test

        # when
        appsV1.delete_namespaced_deployment(name="k8s-test-nginx-deployment", namespace=SaltK8sEngineTest.test_namespace)

        # then
        k8s_events = list(islice(self.event_stream.iter_events(tag='salt/engines/k8s_events/DELETED', match_type="fnmatch"), 3))
        del_events = [e for e in k8s_events if e['type'] == 'DELETED']
        # the number of MODIFIED events depends on many factors, thus we don't gather it
        self.assertEqual(len(k8s_events), 3, "improper total number of events")
        self.assertEqual(len(del_events), 3, "improper total number of 'deleted' events\n{}".format(pp.pformat([{'name': e['object']['metadata']['name'], 'type': e['type']} for e in del_events])))


log = logging.getLogger("k8s-test")
logging.basicConfig(stream=sys.stderr, level=logging.INFO)
pp = pprint.PrettyPrinter(indent=4)

config.load_incluster_config()
coreV1 = client.CoreV1Api()
appsV1 = client.AppsV1Api()
namespace = "salt-provisioning"

if __name__ == "__main__":
    if len(sys.argv) > 1:
        namespace = sys.argv.pop()
        log.info("Changed namespace to: {}".format(namespace))
    unittest.main(verbosity=2)
