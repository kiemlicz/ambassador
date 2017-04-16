import salt.client
import os
import collections

expected_envs = os.listdir("/srv/salt")

caller = salt.client.Caller()
tops = caller.cmd("state.show_top")

if collections.Counter(expected_envs) != collections.Counter(tops.keys()):
    raise ValueError("Expected: {}, but minion returns: {}".format(expected_envs, tops.keys()))

for env, states in tops.iteritems():
    for state in states:
        caller.cmd("state.show_sls", state, env)

#todo detect errors etc