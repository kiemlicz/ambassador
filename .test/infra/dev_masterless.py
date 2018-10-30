def test_java(host):
    java = host.file("/usr/lib/jvm/java-11-oracle/bin/java")
    assert java.exists


# if the service name differs between OSes the this test must be moved to OS directory
def test_redis(host):
    redis_config = host.file("/etc/redis/redis.conf")
    assert redis_config.contains("cluster-enabled no")
    # testing on travis doesn't make sense as
    # "System has not been booted with systemd as init system (PID 1). ..."
    # redis = host.service("redis-server")
    # assert redis.is_running
    # assert redis.is_enabled
