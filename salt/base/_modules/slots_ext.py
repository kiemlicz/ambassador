import os
# till
# https://github.com/saltstack/salt/issues/46771
# this must be wrapped with custom module


def dynamic_append(fun, arg, key, *append):
    ret = __salt__[fun](arg)
    return os.path.join(ret[key], *append) if key in ret else None
