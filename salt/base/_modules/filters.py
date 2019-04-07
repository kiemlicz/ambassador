import re


def find(list, regex):
    return filter(re.compile(regex).search, list)
