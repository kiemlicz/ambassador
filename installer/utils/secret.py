from __future__ import annotations

from typing import Any, Dict


class Secret:
    """
    Retrieved data from REST API
    {
    }
    """
    ATTACHMENTS_KEY = 'attachments'

    def __init__(self, d: Dict[str, Any]) -> Secret:
        for k, v in d.items():
            setattr(self, k, v)
            # fixme how will it behave? I want to add helpers here

    def attachments(self):
        ll = [e[Secret.ATTACHMENTS_KEY] for e in self.secrets if Secret.ATTACHMENTS_KEY in e]
        return [e for sub in ll for e in sub]  # flatten
