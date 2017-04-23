import os
import salt.client
import unittest


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
    def test_states(self):
        self.assertTrue(os.path.isdir(os.path.join(self.saltenv_location, self.saltenv)),
                        msg="salt states not found: {}".format(os.path.join(self.saltenv_location, self.saltenv)))
        self.assertTrue(os.path.isdir(os.path.join(self.pillarenv_location, self.pillarenv)),
                        msg="pillar data not found: {}".format(os.path.join(self.pillarenv_location, self.pillarenv)))
        caller = salt.client.Caller()
        tops = caller.cmd("state.show_top")
        for env, states in tops.iteritems():
            for state in states:
                result = caller.cmd("state.show_sls", state, saltenv=env, pillarenv=self.pillarenv)
                self.assertTrue(isinstance(result, dict),
                                msg="rendering of: {} (saltenv={}, pillarenv={}), failed with: {}".format(state,
                                                                                                          env,
                                                                                                          self.pillarenv,
                                                                                                          result))


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
