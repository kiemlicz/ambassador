import re


def find(list, regex):
    return filter(re.compile(regex).search, list)


def first(generator, default):
    return next(generator, default)


def ips_in_subnet(ip_addresses, cidr):
    return (e for e in ip_addresses if __salt__['network.ip_in_subnet'](e, cidr))


def ifc_for_ip(ip_address, ip_interfaces_dict):
    return next((k for k,v in ip_interfaces_dict.items() if ip_address in v))
