def test_java(host):
    java = host.file("/usr/lib/jvm/java-11-oracle/bin/java")
    assert java.exists
