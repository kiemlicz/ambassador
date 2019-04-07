import logging
from typing import Tuple, List, Iterator, Dict


log = logging.getLogger(__name__)


def fail(ret: Dict, msg: str, comments: List[str] = None) -> Dict:
    log.error(msg)
    ret['result'] = False
    if comments:
        msg += '\nFailure reason: '
        msg += _format_comments(comments)
    ret['comment'] = msg
    return ret


def _format_comments(comments: List[str]) -> str:
    ret = '. '.join(comments)
    if len(comments) > 1:
        ret += '.'
    return ret
