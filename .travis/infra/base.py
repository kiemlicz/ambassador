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


def test_mail(host):
    update_conf = host.file("/etc/exim4/update-exim4.conf.conf")
    assert update_conf.contains("dc_smarthost")
    assert update_conf.contains("smtp.gmail.com::587")
    assert update_conf.contains("MAIN_TLS_ENABLE")
    passwd = host.file("/etc/exim4/passwd")
    assert passwd.contains("username@domain.com:uberpassword")
    addresses = host.file("/etc/email-addresses")
    assert addresses.contains("username")
    assert addresses.contains("username@localhost")
    assert addresses.contains("username@domain.com")
    exim = host.service("exim4")
    assert exim.is_running
