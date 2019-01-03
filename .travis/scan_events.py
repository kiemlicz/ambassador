from __future__ import print_function
import sys
import json
import re
import argparse
import logging


JOB_RET = re.compile("salt/job/\d+/ret/\S+")
RUN_RET = re.compile("salt/run/\d+/ret")

logging.basicConfig(filename='/var/log/salt/scan', level=logging.DEBUG)

parser = argparse.ArgumentParser(description='Scans event dump file.')
parser.add_argument('events', type=str, help='event list file')
args = parser.parse_args()


def _validate_jobs(event_list):
    failures = [e for e in event_list if not e["success"] or e["success"] and e["retcode"] != 0]
    for f in failures:
        logging.error("Job: {}, on minion: {}, finished with error:\n{}\n"
              .format(f["fun"], f["id"], json.dumps(f["return"], indent=4)).decode('string_escape'))

    return len(failures) == 0


def _validate_runs(event_list):
    failures = [e for e in event_list if not e["success"]]
    for f in failures:
        logging.error("Run: {}, from master, finished with error:\n{}\n"
              .format(f["fun"], json.dumps(f["return"], indent=4)).decode('string_escape'))

    return len(failures) == 0


logging.info("Scanning events")


with open(args.events) as f:
    lines = f.readlines()

all_events = [json.loads(l) for l in lines]
jobs = [e["data"] for e in all_events if JOB_RET.match(e["tag"])]
runs = [e["data"] for e in all_events if RUN_RET.match(e["tag"])]

jobs_ok = _validate_jobs(jobs)
runs_ok = _validate_runs(runs)

logging.info("Event count: {}".format(len(all_events)))
if not jobs_ok or not runs_ok:
    sys.exit(3)
