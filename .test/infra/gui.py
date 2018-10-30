def test_packages(host):
    wireshark = host.package("wireshark")
    assert wireshark.is_installed
