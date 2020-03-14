import pytest
import itertools
import os
import json
import pprint
import logging
import sys
import re
import redis
from hashlib import sha256
from pathlib import Path
from typing import List, Dict, Any, Set

import salt.client
import salt.minion
from salt.exceptions import CommandExecutionError

pp = pprint.PrettyPrinter(indent=4)
log = logging.getLogger()
xdist_worker_pattern = re.compile(r"gw(\d+)")


@pytest.fixture(scope="session")
def pillar_location(request) -> str:
    return request.config.getoption("--pillar")


@pytest.fixture(scope="session")
def states_location(request) -> str:
    return request.config.getoption("--states")


@pytest.fixture(scope="session")
def saltenv():
    return "server"


@pytest.fixture(scope="session")
def salt_client() -> salt.client.Caller:
    return salt.client.Caller()


@pytest.fixture(scope="session")
def redis_client() -> redis.Redis:
    return redis.Redis()


@pytest.fixture(scope="session")
def pillars(salt_client, pillar_location) -> List[Dict[str, Any]]:
    # fixme split into equals #CPU chunks
    all_pillars = {}  # state -> list(pillar1, pillar2)
    for pillar_file in Path(pillar_location).glob('**/pillar.example.sls'):
        all_pillars[pillar_file.parent] = []
        with open(str(pillar_file), 'r') as stream:
            for key, group in itertools.groupby(stream, lambda line: line.startswith('---')):
                pillar_string = "".join(list(group))
                rendered = salt_client.cmd("slsutil.renderer", string=pillar_string)
                all_pillars[pillar_file.parent].append(rendered)
    generated = [salt_client.cmd("slsutil.merge_all", list(e)) for e in itertools.product(*all_pillars.values())]
    generated.append({})  # add empty pillar
    return generated


def pillar_chunk(pillars: List[Dict[str, Any]], worker_no: int) -> List[Dict[str, Any]]:
    workers = int(os.environ.get("PYTEST_XDIST_WORKER_COUNT", 1))
    n = -(-len(pillars) // workers)  # so that ceil is taken, not floor
    chunks = [pillars[i:i + n] for i in range(0, len(pillars), n)]
    #number = int(xdist_worker_pattern.search(worker_id).group(1)) if workers > 1 else 0
    return chunks[worker_no]


@pytest.mark.syntax
@pytest.mark.parametrize("worker", list(range(int(os.environ.get("PYTEST_XDIST_WORKER_COUNT", 1)))))
def test_syntax(salt_client: salt.client.Caller, redis_client: redis.Redis, pillars: List[Dict[str, Any]], saltenv: str, states_location: str, worker: int):
    states_path = os.path.join(states_location, saltenv)
    assert os.path.isdir(states_path), "salt states not found: {}".format(states_path)

    def discriminator(sub_pillar: Dict[str, Any], env: str) -> str:
        return sha256("{}:{}".format(json.dumps(sub_pillar, sort_keys=True), env).encode("utf-8")).hexdigest()

    # not running sync_all in Dockerfile so that no Minion ID will be generated
    salt_client.cmd("saltutil.sync_all", saltenv=saltenv)
    tops = salt_client.cmd("state.show_top")
    assert len(tops) != 0, "empty state.show_top output"

    p = pillar_chunk(pillars, worker)
    log.info("Got: %s pillars to test against", len(p))
    for pillar in p:
        try:
            states_evaluated = 0
            states_already_cached = 0
            for env, states in tops.items():
                assert len(states) != 0, "NOT expecting empty state list for env: {}".format(env)
                for state in states:
                    # todo prove this works even for included states
                    # I think this tests just state with its sole pillar, whole pillar product is for nothing
                    pillar_hash = discriminator(pillar[state], env) if state in pillar else None
                    if pillar_hash is None or redis_client.setnx("salt:{}:{}".format(state, pillar_hash), worker):
                        if pillar_hash is None:
                            log.warning("The state %s doesn't contain dedicated pillar, state is re-evaluated", state)
                        result_sls = salt_client.cmd("state.show_sls", state, saltenv=env, pillar=pillar)
                        # fixme how to print immediate feedback? other than log.error?
                        assert isinstance(result_sls, dict), "rendering of: {} (saltenv={}), failed with: {}\npillar: {}".format(state, env, "".join(result_sls) if isinstance(result_sls, list) else result_sls, pp.pformat(pillar))
                        states_evaluated += 1
                    else:
                        states_already_cached += 1
                        log.info("State: %s was already tested", state)
            log.info("Total states evaluated: %s, not evaluated: %s", states_evaluated, states_already_cached)
        except CommandExecutionError:
            log.exception("Unexpected test failure")
            pytest.fail("Unexpected error, failing...")
