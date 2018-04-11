def test_hosts_file(host):
    hosts = host.file("/etc/hosts")
    assert hosts.contains("1.2.3.4")
    assert hosts.contains("coolname")
    assert hosts.contains("192.168.1.1")
    assert hosts.contains("gw")
    assert hosts.contains("mygw")


def test_packages(host):
    vim = host.package("vim")
    assert vim.is_installed
