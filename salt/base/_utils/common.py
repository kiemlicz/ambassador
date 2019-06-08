import logging
from typing import Tuple, List, Any, Dict


log = logging.getLogger(__name__)


def fail(ret: Dict[str, Any], msg: str, comments: List[str] = None) -> Dict[str, Any]:
    if comments:
        msg += '\nFailure reason: '
        msg += _format_comments(comments)
    log.error(msg)
    ret['comment'] = msg
    ret['result'] = False
    return ret


def success(ret: Dict[str, Any], msg: str, comments: List[str] = None) -> Dict[str, Any]:
    if comments:
        msg += _format_comments(comments)
    log.info(msg)
    ret['comment'] = msg
    ret['result'] = True
    return ret


def test(ret: Dict[str, Any], msg: str, comments: List[str] = None) -> Dict[str, Any]:
    if comments:
        msg += _format_comments(comments)
    log.info(msg)
    ret['comment'] = msg
    ret['result'] = None
    return ret


def _format_comments(comments: List[str]) -> str:
    ret = '. '.join(comments)
    if len(comments) > 1:
        ret += '.'
    return ret
