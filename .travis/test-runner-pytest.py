import pytest
import os
import json
import pprint
import logging
import redis
from hashlib import sha256
from typing import List, Dict, Any, Tuple, Set

import test_pillar
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
    return os.environ.get("SALTENV", "server")


@pytest.fixture(scope="session")
def ext_pillar_empty():
    with open("/tmp/pillar.json", "w") as output:
        json.dump({}, output)
    log.info("Empty ext_pillar setup")
    # don't remove file because xdist may be used (other instance still running)
    return


@pytest.fixture(scope="module")
def ext_pillar_saltcheck(pillars_with_dependencies: Tuple[List[Dict[str, Any]], Dict[str, Set[str]]]):
    generated, dependencies = pillars_with_dependencies
    with open("/tmp/pillar.json", "w") as output:
        json.dump(generated[0], output)
    log.info("Saltcheck ext_pillar setup")
    yield
    os.remove("/tmp/pillar.json")
    log.info("Saltcheck pillar removed")


@pytest.fixture(scope="session")
def salt_client(saltenv: str) -> salt.client.Caller:
    return test_pillar.client(saltenv)


@pytest.fixture(scope="session")
def redis_client() -> redis.Redis:
    return redis.Redis()


@pytest.fixture(scope="session")
def pillars_with_dependencies(salt_client: salt.client.Caller, pillar_location: str) -> Tuple[List[Dict[str, Any]], Dict[str, Set[str]]]:
    return test_pillar.generate(salt_client, pillar_location)


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
    log.info(f"Worker #{worker}, got: {len(chunk)} pillars to test against")
    for i in range(len(chunk)):
        log.info(f"Testing {i} out of {len(chunk)}")
        pillar = chunk[i]
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
            pytest.fail("Unexpected error, failing...")


@pytest.mark.saltcheck
def test_saltcheck(salt_client: salt.client.Caller, saltenv: str, ext_pillar_saltcheck: Any):
    try:
        # output formatting
        minion_id = salt_client.cmd("grains.get", "id")
        log.info("Starting tests for minion id: %s", minion_id)
        highstate_result = salt_client.cmd("state.highstate", saltenv=saltenv, l=logging.getLevelName(log.level))
        log.debug("Highstate result:\n%s", pp.pformat(highstate_result))
        assert isinstance(highstate_result, dict), "Unexpected highstate return: {}, expected dict".format(pp.pformat(highstate_result))
        assert all([e['result'] for e in highstate_result.values()]), "Highstate contains failures:\n{}".format(pp.pformat([{**e, 'comment': "".join(e['comment'])} for e in highstate_result.values() if not e['result']]))
        log.info("Running Saltcheck")
        saltcheck_result = salt_client.cmd("saltcheck.run_highstate_tests", saltenv=saltenv)
        log.info("Saltcheck result:\n%s", pp.pformat(saltcheck_result))
    except CommandExecutionError:
        pytest.fail("Unexpected saltcheck test failure")
