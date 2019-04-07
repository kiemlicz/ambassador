import logging
import traceback
import imp

from salt.ext.six import string_types
from salt.exceptions import SaltRenderError

log = logging.getLogger(__name__)


# https://github.com/saltstack/salt/issues/45521
# this is "workaround"
def render(template, saltenv='base', sls='', **kwargs):
    if not isinstance(template, string_types):
        template = template.read()

    log.debug("Template = {}".format(template))

    mod = imp.new_module(sls)
    exec template in mod.__dict__

    if '__env__' not in kwargs:
        setattr(mod, '__env__', saltenv)

    setattr(mod, "saltenv", saltenv)
    setattr(mod, "__salt__", __salt__)
    setattr(mod, "salt", __salt__)
    setattr(mod, "__grains__", __grains__)
    setattr(mod, "grains", __grains__)
    setattr(mod, "__pillar__", __pillar__)
    setattr(mod, "pillar", __pillar__)
    setattr(mod, "__opts__", __opts__)
    setattr(mod, "opts", __opts__)

    try:
        return mod.run()
    except Exception:
        trb = traceback.format_exc()
        raise SaltRenderError(trb)
