import os
import salt.client
import unittest


class ParametrizedTestCase(unittest.TestCase):
    """ TestCase classes that want to be parametrized should
        inherit from this class.
    """

    def __init__(self, methodName='runTest', saltenv=None, location=None):
        super(ParametrizedTestCase, self).__init__(methodName)
        self.saltenv = saltenv
        self.location = location

    @staticmethod
    def parametrize(testcase_klass, saltenv=None, location=None):
        """ Create a suite containing all tests taken from the given
            subclass, passing them the parameter 'param'.
        """
        testloader = unittest.TestLoader()
        testnames = testloader.getTestCaseNames(testcase_klass)
        suite = unittest.TestSuite()
        for name in testnames:
            suite.addTest(testcase_klass(name, saltenv=saltenv, location=location))
        return suite


class AmbassadorTest(ParametrizedTestCase):
    def test_states(self):
        self.assertTrue(os.path.isdir(os.path.join(self.location, self.saltenv)),
                        msg="not found: {}".format(os.path.join(self.location, self.saltenv)))
        caller = salt.client.Caller()
        tops = caller.cmd("state.show_top", self.saltenv)
        for env, states in tops.iteritems():
            for state in states:
                result = caller.cmd("state.show_sls", state, env)
                self.assertTrue(isinstance(result, dict),
                                msg="rendering of: {} (env={}), failed with: {}".format(state, env, result))


if __name__ == "__main__":
    suite = unittest.TestSuite()
    suite.addTest(ParametrizedTestCase.parametrize(AmbassadorTest, saltenv='base', location='/srv/salt'))
    suite.addTest(ParametrizedTestCase.parametrize(AmbassadorTest, saltenv='gui', location='/srv/salt'))
    suite.addTest(ParametrizedTestCase.parametrize(AmbassadorTest, saltenv='dev', location='/srv/salt'))
    unittest.TextTestRunner(verbosity=2).run(suite)
