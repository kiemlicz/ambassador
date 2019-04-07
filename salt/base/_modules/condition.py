def pillar_eq(key_1: str, key_2: str, fail_if_no_key: bool = True) -> bool:
    value_1 = __salt__['pillar.get'](key_1, default=None)
    value_2 = __salt__['pillar.get'](key_2, default=None)

    if fail_if_no_key and (value_1 is None or value_2 is None):
        return False

    return value_1 == value_2
