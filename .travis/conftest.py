import pytest


def pytest_addoption(parser):
    parser.addoption("--tests", action="store", nargs="+", type=str, required=True,
                     help="provide file with data to insert")
    parser.addoption("--pillar", action="store", type=str, default="/srv/salt",
                     help="provide pillar.example.sls location")
    parser.addoption("--states", action="store", type=str, default="/srv/salt",
                     help="provide state tree location")


def pytest_configure(config):
    config.addinivalue_line("markers", "syntax: run syntax tests only")


def pytest_collection_modifyitems(config, items):
    enabled = config.getoption("--tests")
    skip_syntax = pytest.mark.skip(reason="need `--tests syntax` option to run")
    skip_saltcheck = pytest.mark.skip(reason="need `--tests saltcheck` option to run")

    for item in items:
        if "syntax" in item.keywords and "syntax" not in enabled:
            item.add_marker(skip_syntax)
        if "saltcheck" in item.keywords and "saltcheck" not in enabled:
            item.add_marker(skip_saltcheck)
