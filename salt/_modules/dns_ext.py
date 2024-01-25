def aliases(fqdn, separator='.'):
    if fqdn is None:
        return []
    l = fqdn.split(separator)
    result = [l[0]]
    for i in range(1, len(l)):
        result.append("{}.{}".format(result[i-1], l[i]))
    return result
