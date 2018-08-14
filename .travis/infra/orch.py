def test_java(host):
    java = host.file("/usr/lib/jvm/java-10-oracle/bin/java")
    assert java.exists
