def test_unattended_upgrades(host):
    assert host.file("/etc/apt/apt.conf.d/02periodic").exists
    assert host.file("/etc/apt/apt.conf.d/02periodic").contains('APT::Periodic::Enable "1";')
    assert host.file("/etc/apt/apt.conf.d/50unattended-upgrades").exists
    assert host.file("/etc/apt/apt.conf.d/50unattended-upgrades").contains('"origin=Debian,codename=${distro_codename},label=Debian-Security";')
