def test_java(host):
    assert True


def test_redis(host):
    redis_config = host.file("/etc/redis/redis.conf")
    assert redis_config.contains("cluster-enabled no")
    redis = host.service("redis-server")
    assert redis.is_running
    assert redis.is_enabled
