import logging
import itertools
import salt.client
import salt.minion
import pprint
import sys
import json
import os

from pathlib import Path
from typing import List, Dict, Any, Tuple, Set
from salt.exceptions import CommandExecutionError

log = logging.getLogger("test-pillar")
log.addHandler(logging.StreamHandler())
pp = pprint.PrettyPrinter(indent=4)


def generate(salt_client: salt.client.Caller, location: str) -> Tuple[List[Dict[str, Any]], Dict[str, Set[str]]]:
    """
    Generates the test pillar dict based on **every** pillar.example.sls found in Salt State Tree
    All pillar.example.sls'es are found and merged together, if pillar.example.sls contains multiple YAML documents -
    they are treated as separate files and all tested (cartesian product)

    pillar.example.sls must be found right under state root directory (same level as init.sls)
    """
    log.info(f"Generating Pillar (location: {location}/**/pillar.example.sls)")
    all_pillars = {}  # state sls path -> list(pillar1, pillar2)
    state_pillar_dependencies = {}  # state sls name -> list(pillar_key1, pillar_key2)
    try:
        for pillar_file in Path(location).glob('**/pillar.example.sls'):
            sls_dir = pillar_file.parent
            all_pillars[sls_dir] = []
            with open(str(pillar_file), 'r') as stream:
                sls = str(Path(*sls_dir.relative_to(location).parts[1:])).replace("/", ".")  # remove saltenv which is first directory
                for key, group in itertools.groupby(stream, lambda line: line.startswith('---')):
                    if not key:  # filter out entries with: "---" only
                        pillar_string = "".join(list(group))
                        rendered = salt_client.cmd("slsutil.renderer", string=pillar_string)
                        all_pillars[sls_dir].append(rendered)
                        state_pillar_dependencies.setdefault(sls, set()).update(rendered.keys())

        generated = [salt_client.cmd("slsutil.merge_all", list(e)) for e in itertools.product(*all_pillars.values())]
        generated.append({})  # add empty pillar
        # generated's first entry contains every first pillar.example.sls entry
    except Exception as e:
        log.exception(f"Unable to render Pillar ({pillar_file}): \n{pillar_string}")
        raise RuntimeError(f"Cannot generate pillar {pillar_file}") from e

    tops = salt_client.cmd("state.show_top")
    for env, states in tops.items():
        for state in states:
            r = salt_client.cmd("state.show_sls", state, saltenv=env)
            if isinstance(r, dict):
                for result_details in r.values():
                    depends_on = state_pillar_dependencies[result_details['__sls__']] if result_details['__sls__'] in state_pillar_dependencies else None
                    if depends_on is not None:
                        log.debug(f"State {state}, depends on states: {result_details['__sls__']}, pillar keys: {depends_on}")
                        state_pillar_dependencies[state].update(depends_on)
                    else:
                        log.warning(f"Missing pillar.example.sls for sls: {result_details['__sls__']}")

    log.info(f"Generated pillars (#{len(generated)}) based on:\n{pp.pformat({k: len(v) for k, v in all_pillars.items()})}\nDependencies:\n{pp.pformat(state_pillar_dependencies)}")
    return generated, state_pillar_dependencies


def client(saltenv: str) -> salt.client.Caller:
    log.info(f"Salt Client initialization (saltenv: {saltenv})")
    client = salt.client.Caller()
    # don't run sync_all in Dockerfile so that no Minion ID is generated there
    sync_result = client.cmd("saltutil.sync_all", saltenv="server")
    log.info(f"saltutil.sync_all: {pp.pformat(sync_result)}")
    if not sync_result['modules'] or not sync_result['utils'] or not sync_result['states']:
        log.warning("Modules to sync not found, the tests may fail")
    client.function("sys.reload_modules")
    log.info(f"Client reloaded after saltutil.sync_all")  # otherwise the custom modules wouldn't be visible under this `client` instance
    return client


if __name__ == "__main__":
    o = sys.argv[1]
    pillar_path = os.path.join(o, "pillar.json")
    client = client("server")
    pillars, deps = generate(client, "/srv/salt/")
    with open(pillar_path, "w") as output:
        json.dump(pillars[0], output)
    log.info(f"Wrote pillar to: {pillar_path}")
