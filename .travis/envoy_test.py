from __future__ import print_function
import itertools
import os
import traceback
import unittest

import salt.client
import salt.minion
import salt.syspaths as syspaths
from salt.exceptions import CommandExecutionError


class ParametrizedTestCase(unittest.TestCase):
    """ TestCase classes that want to be parametrized should
        inherit from this class.
    """

    def __init__(self,
                 methodName='runTest',
                 saltenv=None,
                 pillarenv=None,
                 saltenv_location=None,
                 pillarenv_location=None):
        super(ParametrizedTestCase, self).__init__(methodName)
        self.saltenv = saltenv
        self.saltenv_location = saltenv_location
        self.pillarenv = pillarenv
        self.pillarenv_location = pillarenv_location

    @staticmethod
    def parametrize(testcase_klass,
                    saltenv=None,
                    pillarenv=None,
                    saltenv_location='/srv/salt',
                    pillarenv_location='/srv/pillar/'):
        """ Create a suite containing all tests taken from the given
            subclass, passing them the parameter 'param'.
        """
        testloader = unittest.TestLoader()
        testnames = testloader.getTestCaseNames(testcase_klass)
        suite = unittest.TestSuite()
        for name in testnames:
            suite.addTest(testcase_klass(name,
                                         saltenv=saltenv,
                                         pillarenv=pillarenv,
                                         saltenv_location=saltenv_location,
                                         pillarenv_location=pillarenv_location
                                         )
                          )
        return suite


class EnvoyTest(ParametrizedTestCase):
    def _get_client(self):
        self.assertTrue(os.path.isdir(os.path.join(self.saltenv_location, self.saltenv)),
                        msg="salt states not found: {}".format(os.path.join(self.saltenv_location, self.saltenv)))
        self.assertTrue(os.path.isdir(os.path.join(self.pillarenv_location, self.pillarenv)),
                        msg="pillar data not found: {}".format(os.path.join(self.pillarenv_location, self.pillarenv)))
        # ugly hack, as pillarenv is respected only when set in config..., passing `pillarenv=???` has no effect
        conf = salt.config.minion_config(os.path.join(syspaths.CONFIG_DIR, 'minion'))
        conf['pillarenv'] = self.pillarenv
        return salt.client.Caller(mopts=conf)

    def test_states_syntax(self):
        caller = self._get_client()
        print("saltenv: {}, pillarenv: {} ".format(self.saltenv, self.pillarenv), end='')
        try:
            tops = caller.cmd("state.show_top")
            self.assertFalse(len(tops) == 0, "empty state.show_top output")
            for env, states in tops.items():
                self.assertFalse(len(states) == 0, "empty state list for env: {}".format(env))
                for state in states:
                    result_sls = caller.cmd("state.show_sls", state, saltenv=env)
                    self.assertTrue(isinstance(result_sls, dict),
                                    msg="rendering of: {} (saltenv={}, pillarenv={}), failed with: {}".format(state,
                                                                                                              env,
                                                                                                              self.pillarenv,
                                                                                                              "".join(result_sls) if isinstance(result_sls, list) else result_sls))
        except CommandExecutionError:
            traceback.print_exc()
            self.fail("Unexpected error, failing...")


if __name__ == "__main__":
    suite = unittest.TestSuite()
    saltenvs = ["base", "dev", "server"]
    pillarenvs = ["empty", "base", "gui", "dev", "orch1", "server"]
    for saltenv, pillarenv in itertools.product(saltenvs, pillarenvs):
        suite.addTest(ParametrizedTestCase.parametrize(EnvoyTest, saltenv=saltenv, pillarenv=pillarenv))
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    if not result.wasSuccessful():
        raise SystemError("Some tests have failed, check logs")
