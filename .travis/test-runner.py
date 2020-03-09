from __future__ import print_function

import itertools
import os
import json
import unittest
import pprint
import logging
import sys
import argparse
from pathlib import Path
from typing import List, Dict, Any

import salt.client
import salt.minion
from salt.exceptions import CommandExecutionError


pp = pprint.PrettyPrinter(indent=4)
log = logging.getLogger()
# this settings override salt's one causing log to be terrible, at least copy the default format
# log.level = logging.getLevelName(os.environ.get('LOG_LEVEL', 'INFO'))
log.level = logging.INFO
stream_handler = logging.StreamHandler(sys.stdout)
log.addHandler(stream_handler)


class ParametrizedSaltTestCase(unittest.TestCase):
    """ TestCase classes that want to be parametrized should
        inherit from this class.
    """

    def __init__(self,
                 methodName='runTest',
                 saltenv=None,
                 saltenv_location=None,
                 pillar=None):
        super(ParametrizedSaltTestCase, self).__init__(methodName)
        self.saltenv = saltenv
        self.saltenv_location = saltenv_location
        self.pillar = pillar

    @staticmethod
    def _get_client() -> salt.client.Caller:
        return salt.client.Caller()

    @staticmethod
    def generate_pillars(pillar_location="/srv/salt") -> List[Dict[str, Any]]:
        '''
        Generates the test pillar dict based on **every** pillar.example.sls found in Salt State Tree
        All pillar.example.sls'es are found and merged together, if pillar.example.sls contains multiple YAML documents -
        they are treated as separate files and both tested (cartesian product)

         pillar.example.sls must be found right under state root directory (same level as init.sls)
        :param pillar_location: where to look for pillar.example.sls
        :return: list of all generated pillars, the first list element must contain all first entries from pillar.example.sls
        '''
        caller = ParametrizedSaltTestCase._get_client()
        all_pillars = {}  # state -> list(pillar1, pillar2)
        for pillar_file in Path(pillar_location).glob('**/pillar.example.sls'):
            all_pillars[pillar_file.parent] = []
            with open(str(pillar_file), 'r') as stream:
                for key, group in itertools.groupby(stream, lambda line: line.startswith('---')):
                    pillar_string = "".join(list(group))
                    rendered = caller.cmd("slsutil.renderer", string=pillar_string)
                    all_pillars[pillar_file.parent].append(rendered)
        generated = [caller.cmd("slsutil.merge_all", list(e)) for e in itertools.product(*all_pillars.values())]
        generated.append({})  # add empty pillar
        return generated

    @staticmethod
    def parametrize(testcase_klass,
                    pillar: List[Dict[str, Any]],
                    saltenv: str = None,
                    saltenv_location: str = '/srv/salt',
                    ) -> unittest.TestSuite:
        """ Create a suite containing all tests taken from the given
            subclass, passing them the parameter 'param'.
        """
        testloader = unittest.TestLoader()
        testnames = testloader.getTestCaseNames(testcase_klass)
        suite = unittest.TestSuite()
        for test_case_name, pillar in itertools.product(testnames, pillar):
            suite.addTest(testcase_klass(test_case_name,
                                         saltenv=saltenv,
                                         saltenv_location=saltenv_location,
                                         pillar=pillar
                                         )
                          )
        return suite


class SaltStatesTest(ParametrizedSaltTestCase):
    def test_states_syntax(self):
        self.assertTrue(os.path.isdir(os.path.join(self.saltenv_location, self.saltenv)),
                        msg="salt states not found: {}".format(os.path.join(self.saltenv_location, self.saltenv)))
        caller = self._get_client()
        log.info("saltenv: %s", self.saltenv)
        try:
            # not running sync_all in Dockerfile so that no Minion ID will be generated
            caller.cmd("saltutil.sync_all", saltenv=self.saltenv)
            tops = caller.cmd("state.show_top")
            self.assertFalse(len(tops) == 0, "empty state.show_top output")
            for env, states in tops.items():
                self.assertFalse(len(states) == 0, "NOT expecting empty state list for env: {}".format(env))
                for state in states:
                    result_sls = caller.cmd("state.show_sls", state, saltenv=env, pillar=self.pillar)
                    self.assertTrue(
                        isinstance(result_sls, dict),
                        msg="rendering of: {} (saltenv={}), failed with: {}\npillar: {}".format(state, env, "".join(result_sls) if isinstance(result_sls, list) else result_sls, pp.pformat(self.pillar))
                    )
        except CommandExecutionError:
            log.exception("Unexpected test failure")
            self.fail("Unexpected error, failing...")


class SaltCheckTest(ParametrizedSaltTestCase):
    def setUp(self) -> None:
        with open("/tmp/pillar.json", "w") as output:
            json.dump(self.pillar, output)
        log.info("Pillar setup for Saltcheck completed")

    def tearDown(self) -> None:
        os.remove("/tmp/pillar.json")
        log.info("Pillar for Saltcheck removed")

    def test_saltcheck(self):
        caller = self._get_client()
        try:
            minion_id = caller.cmd("grains.get", "id")
            log.info("Starting tests for minion id: %s", minion_id)
            highstate_result = caller.cmd("state.highstate", saltenv=self.saltenv)
            log.info("Highstate result:\n%s", pp.pformat(highstate_result))
            self._assertHighstateResult(highstate_result)
            saltcheck_result = caller.cmd("saltcheck.run_highstate_tests", saltenv=self.saltenv)
            log.info("Saltcheck result:\n%s", pp.pformat(saltcheck_result))
        except CommandExecutionError:
            log.exception("Unexpected saltcheck test failure")
            self.fail("Unexpected saltcheck test failure")

    def _assertHighstateResult(self, result):
        if not isinstance(result, dict):
            log.error("Unexpected (expected dict) highstate return: %s", result)
            self.fail("Unexpected (expected dict) highstate return")
        if not all([e['result'] for e in result.values()]):
            output = [{**e, 'comment': "".join(e['comment'])} for e in result.values() if not e['result']]
            log.error("Highstate contains failures:\n%s", pp.pformat(output))
            self.fail("Highstate contains failures")


if __name__ == "__main__":
    suite = unittest.TestSuite()

    parser = argparse.ArgumentParser()
    parser.add_argument('--tests', nargs="+", default='dry', type=str, required=True)
    args = parser.parse_args()

    pillars = ParametrizedSaltTestCase.generate_pillars()
    if 'dry' in args.tests:
        log.info("Adding dry run tests")
        # testing only for 'top-most' saltenv which includes all other saltenvs
        suite.addTest(ParametrizedSaltTestCase.parametrize(SaltStatesTest, pillar=pillars, saltenv="server"))
    if 'saltcheck' in args.tests:
        log.info("Adding Saltcheck tests")
        suite.addTest(ParametrizedSaltTestCase.parametrize(SaltCheckTest, pillar=pillars[:1], saltenv="server"))

    log.info("Starting tests")
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    if not result.wasSuccessful():
        raise SystemError("Some tests have failed, check logs")
