import argparse
import json
import os
import requests
from jinja2 import Template


# pip install requests
# pip install jinja2

def dir(string):
    if os.path.isdir(string):
        return string
    else:
        raise argparse.ArgumentTypeError("not a directory")


parser = argparse.ArgumentParser(description='Uploads templates to running foreman server.')
parser.add_argument('url', type=str, help='foreman base url')
parser.add_argument('templates_dir', type=dir)
parser.add_argument('-l', '--login', dest='username', help='username')
parser.add_argument('-p', '--password', dest='password', help='password')
parser.add_argument('-d', '--domain', type=str, dest='domain',
                    help='foreman network domain (as used in fqdn), required for domain templates')
parser.add_argument('-n', '--network', type=str, dest='net_addr', help='Network address')
parser.add_argument('-m', '--mask', type=str, dest='net_mask', help='Network mask')
parser.add_argument('-g', '--gateway', type=str, dest='gateway', help='Default gateway')
parser.add_argument('-a', '--network_name', type=str, dest='net_name', help='network name (alias)')

args = parser.parse_args()
path = args.templates_dir

s = requests.Session()
if args.username is not None:
    s.auth = (args.username, args.password)
headers = {'Accept': 'application/json', 'Content-Type': 'application/json'}


def _list_files_by_prefix(prefix):
    return ["{}/{}".format(path, f) for f in os.listdir(path) if f.startswith(prefix)]


def _assert_response(response):
    if response.status_code < 200 or response.status_code >= 300:
        raise ValueError(
            "received error response code: {}".format(response.status_code))


def arch():
    added_ids = []
    for file in _list_files_by_prefix("arch_"):
        with open(file, 'r') as f:
            response = s.post("{0}/api/architectures".format(args.url), headers=headers, data=f.read(), verify=False)
            _assert_response(response)
            added_ids.append({'id': str(json.loads(response.text)['id'])})  # foreman's stupid format
    return json.dumps(added_ids)


def domain(domain_name):
    added_domain_ids = []
    for file in _list_files_by_prefix("domain_"):
        with open(file, 'r') as f:
            t = Template(f.read())
            response = s.post("{0}/api/domains".format(args.url), headers=headers, data=
            t.render(domain_name=json.dumps(domain_name)), verify=False)
            _assert_response(response)
            added_domain_ids.append({'id': str(json.loads(response.text)['id'])})
    return json.dumps(added_domain_ids)


# NL in .json won't work but '\n' will
def provisioning_templates():
    for file in _list_files_by_prefix("pt_"):
        with open(file, 'r') as f:
            # load and dump to escape control characters
            response = s.post("{0}/api/provisioning_templates".format(args.url), headers=headers,
                              data=json.dumps(json.load(f, strict=False)), verify=False)
            _assert_response(response)


def get_partition_table(name_prefix):
    # mind results dividing in pages
    response = s.get("{}/api/ptables".format(args.url), verify=False)
    _assert_response(response)
    return json.dumps(
        [{'id': e['id']} for e in json.loads(response.text)['results'] if e['name'].startswith(name_prefix)])


def get_installation_media(name_prefix):
    response = s.get("{}/api/media".format(args.url), verify=False)
    _assert_response(response)
    return json.dumps(
        [{'id': e['id']} for e in json.loads(response.text)['results'] if e['name'].startswith(name_prefix)])


def get_proxy_id():
    response = s.get("{}/api/smart_proxies".format(args.url), verify=False)
    _assert_response(response)
    return [e['id'] for e in json.loads(response.text)['results']][0]


def operating_system(arch_list, partition_table_list, installation_media_list):
    for file in _list_files_by_prefix("os_", ):
        with open(file, 'r') as f:
            t = Template(f.read())
            response = s.post("{0}/api/operatingsystems".format(args.url), headers=headers,
                              data=t.render(arch_list=arch_list, partition_table_list=partition_table_list,
                                            installation_media_list=installation_media_list), verify=False)
            _assert_response(response)


def subnet(domain_name, net_name, net_addr, net_mask, gateway, domain_ids_list, proxy_id):
    for file in _list_files_by_prefix("subnet_"):
        with open(file, 'r') as f:
            t = Template(f.read())
            response = s.post("{0}/api/subnets".format(args.url), headers=headers,
                              data=t.render(domain_name=json.dumps(domain_name), net_addr=json.dumps(net_addr),
                                            net_name=json.dumps(net_name), net_mask=json.dumps(net_mask),
                                            gateway=json.dumps(gateway),
                                            domain_ids_list=domain_ids_list, proxy_id=proxy_id), verify=False)
            _assert_response(response)


def _remove_salt_states(to_remove):
    print("States to remove: {}".format(to_remove))
    for entry in to_remove:
        response = s.delete("{0}/salt/api/v2/salt_states/{1}".format(args.url, entry))
        _assert_response(response)


def remove_all_salt_states():
    all_states = s.get("{}/salt/api/v2/salt_states?per_page=1000".format(args.url), headers=headers, verify=False)
    _assert_response(all_states)
    _remove_salt_states([e['id'] for e in json.loads(all_states.text)['results']])


def import_salt_states(proxy_id, envs):
    import_result = s.post("{0}/salt/api/v2/salt_states/import/{1}".format(args.url, proxy_id), headers=headers,
                           verify=False)
    _assert_response(import_result)
    changes = json.loads(import_result.text)['changes']
    all_states = s.get("{}/salt/api/v2/salt_states?per_page=1000".format(args.url), headers=headers, verify=False)
    names_to_remove = []
    for env in changes.keys():
        if env in envs:
            for state in changes[env]["add"]:
                if state.startswith("salt.") or state.endswith(".top"):
                    names_to_remove.append(state)
                for e in envs:
                    if state.startswith("{}.".format(e)):
                        names_to_remove.append(state)
        else:
            names_to_remove.extend(changes[env]["add"])
    print("Parsing done, names to remove: {}".format(names_to_remove))
    _remove_salt_states([e['id'] for e in json.loads(all_states.text)['results'] if e['name'] in names_to_remove])


domain_ids = domain(args.domain)
print("Domains set")
subnet(args.domain, args.net_name, args.net_addr, args.net_mask, args.gateway, domain_ids, get_proxy_id())
print("Subnets set")
arch_list = arch()
print("Architectures set")
provisioning_templates()
print("Provisioning templates added")
operating_system(arch_list, get_partition_table("Preseed"), get_installation_media("Debian"))
print("Operating system created")
remove_all_salt_states()
import_salt_states(get_proxy_id(), ["base", "gui", "dev"])
print("Salt states imported")
#salt bogus environments are left