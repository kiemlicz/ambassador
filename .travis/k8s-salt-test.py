import unittest
import logging
import sys
import json
import time
import re
import pprint
from kubernetes import client, config


class SaltK8sEngineTest(unittest.TestCase):
    test_namespace = "salt-provisioning-test"

    def setUp(self) -> None:
        # with testinfra it is impossible to create runner client
        # use python API (not netapi)

        ns = client.V1Namespace(metadata=client.V1ObjectMeta(name=SaltK8sEngineTest.test_namespace))
        coreV1.create_namespace(body=ns)

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

    def tearDown(self) -> None:
        coreV1.delete_namespace(name=SaltK8sEngineTest.test_namespace)

    def test_01_k8s_events(self):
        # given
        appsV1.create_namespaced_deployment(namespace=SaltK8sEngineTest.test_namespace, body=self.deployment)

        # when
        # maybe just wait for event from salt master
        time.sleep(30)

        # then
        # fixme this file will contain all k8s events from given namespace
        #o = self.saltMaster.run("cat /var/log/salt/events")
        #j = [json.loads(e) for e in o.stdout.splitlines()]
        #k8s_events = [e for e in j if k8s_events_tag.match(e['tag'])]
        #add_events = [e for e in k8s_events if e['tag'] == 'salt/engines/k8s_events/ADDED']
        #mod_events = [e for e in k8s_events if e['tag'] == 'salt/engines/k8s_events/MODIFIED']
        #
        #self.assertEqual(len(add_events), 2)
        #self.assertEqual(len(mod_events), 6)
        #
        #pods = {}
        #for e in mod_events:
        #    pods.setdefault(e['data']['object']['metadata']['name'], []).append(e['data'])
        #
        #self.assertEqual(len(pods), 2, "There must be two Nginx PODs only")
        #
        #for k, v in pods.items():
        #    if len(v) > 1:
        #        last = v[-1:][0]
        #        log.info("LAST => {}".format(last['object']))
        #        self.assertEqual(last['object']['status']['phase'], "Running")
        #        self.assertRegexpMatches(last['object']['status']['hostIP'], "\d+\.\d+\.\d+\.\d+")
        #        self.assertRegexpMatches(last['object']['status']['podIP'], "\d+\.\d+\.\d+\.\d+")
        #        log.debug("Last modified event status:\n{}".format(pp.pformat(last)))
        #    else:
        #        self.fail("no MODIFIED event received")


log = logging.getLogger("k8s-test")
logging.basicConfig(stream=sys.stderr, level=logging.INFO)
pp = pprint.PrettyPrinter(indent=4)

config.load_incluster_config()
coreV1 = client.CoreV1Api()
appsV1 = client.AppsV1Api()
namespace = "salt-provisioning"

k8s_events_tag = re.compile("salt/engines/k8s_events/\S+")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        namespace = sys.argv.pop()
        log.info("Changed namespace to: {}".format(namespace))
    unittest.main(verbosity=1)
