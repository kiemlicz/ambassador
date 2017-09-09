import assertions
import os
import salt.client
import traceback
import unittest
from salt.exceptions import CommandExecutionError


class ParametrizedTestCase(unittest.TestCase):
    """ TestCase classes that want to be parametrized should
        inherit from this class.
    """

    def __init__(self, methodName='runTest', saltenv=None, pillarenv=None, saltenv_location=None,
                 pillarenv_location=None):
        super(ParametrizedTestCase, self).__init__(methodName)
        self.saltenv = saltenv
        self.saltenv_location = saltenv_location
        self.pillarenv = pillarenv
        self.pillarenv_location = pillarenv_location

    @staticmethod
    def parametrize(testcase_klass, saltenv=None, pillarenv=None,
                    saltenv_location='/srv/salt',
                    pillarenv_location='/srv/pillar/'):
        """ Create a suite containing all tests taken from the given
            subclass, passing them the parameter 'param'.
        """
        testloader = unittest.TestLoader()
        testnames = testloader.getTestCaseNames(testcase_klass)
        suite = unittest.TestSuite()
        for name in testnames:
            suite.addTest(testcase_klass(name, saltenv=saltenv, pillarenv=pillarenv, saltenv_location=saltenv_location,
                                         pillarenv_location=pillarenv_location))
        return suite


class AmbassadorTest(ParametrizedTestCase):
    def _get_client(self):
        self.assertTrue(os.path.isdir(os.path.join(self.saltenv_location, self.saltenv)),
                        msg="salt states not found: {}".format(os.path.join(self.saltenv_location, self.saltenv)))
        self.assertTrue(os.path.isdir(os.path.join(self.pillarenv_location, self.pillarenv)),
                        msg="pillar data not found: {}".format(os.path.join(self.pillarenv_location, self.pillarenv)))
        return salt.client.Caller()

    def test_states_syntax(self):
        caller = self._get_client()
        try:
            tops = caller.cmd("state.show_top")
            self.assertFalse(len(tops) == 0, "empty state.show_top output")
            for env, states in tops.iteritems():
                self.assertFalse(len(states) == 0, "empty state list for env: {}".format(env))
                for state in states:
                    result_sls = caller.cmd("state.show_sls", state, saltenv=env, pillarenv=self.pillarenv)
                    self.assertTrue(isinstance(result_sls, dict),
                                    msg="rendering of: {} (saltenv={}, pillarenv={}), failed with: {}".format(state,
                                                                                                              env,
                                                                                                              self.pillarenv,
                                                                                                              result_sls))
        except CommandExecutionError:
            traceback.print_exc()
            self.fail("Unexpected error, failing...")

    def test_pkgs(self):
        caller = self._get_client()
        result_dict = caller.cmd("state.show_sls", "pkgs", saltenv=self.saltenv, pillarenv=self.pillarenv)
        l = result_dict['pkgs']['pkg']
        #find pkgs in list of dicts and flatten
        pkgs = [item for sublist in (e['pkgs'] for e in l if 'pkgs' in e) for item in sublist]
        self.assertTrue(isinstance(pkgs, list))
        self.assertTrue(assertions.assert_pkgs(pkgs, self.pillarenv),
                        msg="pkgs state contains improper packages list (saltenv: {}, pillarenv: {}), packages:{}".format(
                            self.saltenv, self.pillarenv, pkgs))
        c = result_dict['pkgs']['cmd']
        #find commands in list of dicts and flatten
        cmds = [item for sublist in (e['names'] for e in c if 'names' in e) for item in sublist]
        self.assertTrue(assertions.assert_cmds(cmds, self.pillarenv),
                        msg="pkgs state contains improper post_cmds list (saltenv: {}, pillarenv: {}), cmds: {}".format(
                            self.saltenv, self.pillarenv, cmds))


if __name__ == "__main__":
    suite = unittest.TestSuite()
    suite.addTest(ParametrizedTestCase.parametrize(AmbassadorTest, saltenv='base', pillarenv='empty'))
    suite.addTest(ParametrizedTestCase.parametrize(AmbassadorTest, saltenv='gui', pillarenv='empty'))
    suite.addTest(ParametrizedTestCase.parametrize(AmbassadorTest, saltenv='dev', pillarenv='empty'))
    suite.addTest(ParametrizedTestCase.parametrize(AmbassadorTest, saltenv='base', pillarenv='one_user'))
    suite.addTest(ParametrizedTestCase.parametrize(AmbassadorTest, saltenv='gui', pillarenv='one_user'))
    suite.addTest(ParametrizedTestCase.parametrize(AmbassadorTest, saltenv='dev', pillarenv='one_user'))
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    if not result.wasSuccessful():
        raise SystemError("Some tests have failed, check logs")
