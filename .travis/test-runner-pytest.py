import pytest
import itertools
import os
import json
import pprint
import logging
import redis
from hashlib import sha256
from pathlib import Path
from typing import List, Dict, Any, Tuple, Set

import salt.client
import salt.minion
from salt.exceptions import CommandExecutionError

pp = pprint.PrettyPrinter(indent=4)
log = logging.getLogger("test-runner")


@pytest.fixture(scope="session")
def pillar_location(request) -> str:
    return request.config.getoption("--pillar")


@pytest.fixture(scope="session")
def states_location(request) -> str:
    return request.config.getoption("--states")


@pytest.fixture(scope="session")
def saltenv() -> str:
    return "server"


@pytest.fixture(scope="session")
def ext_pillar_empty():
    with open("/tmp/pillar.json", "w") as output:
        json.dump({}, output)
    log.info("Empty ext_pillar setup")
    # don't remove file because xdist may be used (other instance still running)
    return


@pytest.fixture(scope="session")
def salt_client(saltenv: str) -> salt.client.Caller:
    client = salt.client.Caller()
    # not running sync_all in Dockerfile so that no Minion ID is generated
    client.cmd("saltutil.sync_all", saltenv=saltenv)
    return client


@pytest.fixture(scope="session")
def redis_client() -> redis.Redis:
    return redis.Redis()


@pytest.fixture(scope="session")
def pillars_with_dependencies(salt_client: salt.client.Caller, pillar_location: str) -> Tuple[List[Dict[str, Any]], Dict[str, Set[str]]]:
    all_pillars = {}  # state sls path -> list(pillar1, pillar2)
    state_pillar_dependencies = {}  # state sls name -> list(pillar_key1, pillar_key2)
    for pillar_file in Path(pillar_location).glob('**/pillar.example.sls'):
        sls_dir = pillar_file.parent
        all_pillars[sls_dir] = []
        with open(str(pillar_file), 'r') as stream:
            sls = str(Path(*sls_dir.relative_to(pillar_location).parts[1:])).replace("/", ".")  # remove saltenv which is first directory
            for key, group in itertools.groupby(stream, lambda line: line.startswith('---')):
                if not key:  # filter out entries with: "---" only
                    pillar_string = "".join(list(group))
                    rendered = salt_client.cmd("slsutil.renderer", string=pillar_string)
                    all_pillars[sls_dir].append(rendered)
                    state_pillar_dependencies.setdefault(sls, set()).update(rendered.keys())
    generated = [salt_client.cmd("slsutil.merge_all", list(e)) for e in itertools.product(*all_pillars.values())]
    generated.append({})  # add empty pillar

    tops = salt_client.cmd("state.show_top")
    for env, states in tops.items():
        for state in states:
            r = salt_client.cmd("state.show_sls", state, saltenv=env)
            if isinstance(r, dict):
                for result_details in r.values():
                    depends_on = state_pillar_dependencies[result_details['__sls__']] if result_details['__sls__'] in state_pillar_dependencies else None
                    if depends_on is not None:
                        log.info("State %s, depends on states: %s, pillar keys: %s", state, result_details['__sls__'], depends_on)
                        state_pillar_dependencies[state].update(depends_on)
                    else:
                        log.warning("Missing pillar.example.sls for sls: %s", result_details['__sls__'])

    log.info("Generated pillars (#%s) based on:\n%s\nDependencies:\n%s", len(generated), pp.pformat({k: len(v) for k, v in all_pillars.items()}), pp.pformat(state_pillar_dependencies))
    return generated, state_pillar_dependencies


def pillar_chunk(pillars: List[Dict[str, Any]], worker_no: int) -> List[Dict[str, Any]]:
    """
    For given worker get deterministically its work chunk
    :param pillars: all generated pillars
    :param worker_no:
    :return: worker_no's chunk
    """
    workers = int(os.environ.get("PYTEST_XDIST_WORKER_COUNT", 1))
    n = len(pillars) // workers
    chunks = [pillars[i:i + n] for i in range(0, len(pillars), n)]
    i = 0
    for not_distributed in pillars[n*workers:]:
        chunks[i].append(not_distributed)
        i += 1
    return chunks[worker_no]


@pytest.mark.syntax
@pytest.mark.parametrize("worker", list(range(int(os.environ.get("PYTEST_XDIST_WORKER_COUNT", 1)))))
def test_syntax(salt_client: salt.client.Caller, redis_client: redis.Redis, pillars_with_dependencies: Tuple[List[Dict[str, Any]], Dict[str, Set[str]]], ext_pillar_empty: Any, saltenv: str, states_location: str, worker: int):
    states_path = os.path.join(states_location, saltenv)
    assert os.path.isdir(states_path), "salt states not found: {}".format(states_path)

    pillars, pillar_dependencies = pillars_with_dependencies

    def discriminator(state: str, pillar: Dict[str, Any], env: str) -> str:
        d = env
        pillar_keys = sorted(pillar_dependencies[state])
        for k in pillar_keys:
            d += json.dumps(pillar[k], sort_keys=True)
        return sha256(d.encode("utf-8")).hexdigest()

    tops = salt_client.cmd("state.show_top")
    assert len(tops) != 0, "NOT expecting empty state.show_top output"
    chunk = pillar_chunk(pillars, worker)
    log.info("Got: %s pillars to test against", len(chunk))
    for pillar in chunk:
        try:
            states_evaluated = 0
            states_already_cached = 0
            for env, states in tops.items():
                assert len(states) != 0, "NOT expecting empty state list for env: {}".format(env)
                for state in states:
                    pillar_hash = discriminator(state, pillar, env) if state in pillar else None
                    if pillar_hash is None or redis_client.setnx("salt:{}:{}".format(state, pillar_hash), worker):
                        if pillar_hash is None:
                            log.warning("The state %s doesn't contain dedicated pillar, state is re-evaluated", state)
                        result_sls = salt_client.cmd("state.show_sls", state, saltenv=env, pillar=pillar)
                        assert isinstance(result_sls, dict), "rendering of: {} (saltenv={}), failed with: {}\npillar: {}".format(state, env, "".join(result_sls) if isinstance(result_sls, list) else result_sls, pp.pformat(pillar))
                        states_evaluated += 1
                    else:
                        states_already_cached += 1
                        log.info("State: %s was already tested", state)
            log.info("Total states evaluated: %s, not evaluated: %s", states_evaluated, states_already_cached)
        except CommandExecutionError:
            log.exception("Unexpected test failure")
            pytest.fail("Unexpected error, failing...")
