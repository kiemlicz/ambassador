import re
import logging


log = logging.getLogger(__name__)


def find(list, regex):
    return filter(re.compile(regex).search, list)


def first(generator, default):
    return next(generator, default)


def ips_in_subnet(ip_addresses, cidr):
    if not ip_addresses:
        log.warning("Cannot filter addresses by CIDR: ip_addresses empty")
        return iter(())
    return (e for e in ip_addresses if __salt__['network.ip_in_subnet'](e, cidr))


def ifc_for_ip(ip_address, ip_interfaces_dict):
    log.info("Available interfaces: %s\nIP: %s", ip_interfaces_dict, ip_address)
    if not ip_interfaces_dict:
        log.error("Cannot find interface for IP: %s, empty iterfaces dict: %s", ip_address, ip_interfaces_dict)
    return next((k for k,v in ip_interfaces_dict.items() if ip_address in v))
