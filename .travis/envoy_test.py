from __future__ import print_function

import itertools
import os
import traceback
import unittest
from pathlib import Path

import salt.client
import salt.minion
from salt.exceptions import CommandExecutionError


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
    def _get_client():
        return salt.client.Caller()

    @staticmethod
    def generate_pillars(pillar_location):
        '''
        Generates the test pillar dict based on **every** pillar.example.sls found in Salt State Tree
        All pillar.example.sls'es are found and merged together, if pillar.example.sls contains multiple YAML documents -
        they are treated as separate files and both tested (cartesian product)

         pillar.example.sls must be found right under state root directory (same level as init.sls)
        :param pillar_location: where to look for pillar.example.sls
        :return:
        '''
        caller = ParametrizedSaltTestCase._get_client()
        all_pillars = {}  # state -> list(pillar1, pillar2)
        for pillar_file in Path(pillar_location).glob('**/pillar.example.sls'):
            all_pillars[pillar_file.parent] = []
            with open(str(pillar_file), 'r') as stream:
                for key, group in itertools.groupby(stream, lambda line: line.startswith('---')):
                    if not key:
                        pillar_string = "".join([g for g in group])
                        rendered = caller.cmd("slsutil.renderer", string=pillar_string)
                        all_pillars[pillar_file.parent].append(rendered)
        generated = [caller.cmd("slsutil.merge_all", list(e)) for e in itertools.product(*all_pillars.values())]
        generated.append({})  # add empty pillar
        return generated

    @staticmethod
    def parametrize(testcase_klass,
                    saltenv=None,
                    pillar_location='/srv/salt',  # pillar.example.sls location
                    saltenv_location='/srv/salt',
                    ):
        """ Create a suite containing all tests taken from the given
            subclass, passing them the parameter 'param'.
        """
        testloader = unittest.TestLoader()
        testnames = testloader.getTestCaseNames(testcase_klass)
        suite = unittest.TestSuite()
        for name, pillar in itertools.product(testnames, ParametrizedSaltTestCase.generate_pillars(pillar_location)):
            suite.addTest(testcase_klass(name,
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
        print("saltenv: {}".format(self.saltenv), end='')
        try:
            tops = caller.cmd("state.show_top")
            self.assertFalse(len(tops) == 0, "empty state.show_top output")
            for env, states in tops.items():
                self.assertFalse(len(states) == 0, "NOT expecting empty state list for env: {}".format(env))
                for state in states:
                    result_sls = caller.cmd("state.show_sls", state, saltenv=env, pillar=self.pillar)
                    self.assertTrue(
                        isinstance(result_sls, dict),
                        msg="rendering of: {} (saltenv={}), failed with: {}".format(state, env, "".join(result_sls) if isinstance(result_sls, list) else result_sls)
                    )
        except CommandExecutionError:
            traceback.print_exc()
            self.fail("Unexpected error, failing...")


if __name__ == "__main__":
    suite = unittest.TestSuite()
    # testing only for 'top-most' saltenv which includes all other saltenvs
    suite.addTest(ParametrizedSaltTestCase.parametrize(SaltStatesTest, saltenv="server"))
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    if not result.wasSuccessful():
        raise SystemError("Some tests have failed, check logs")
