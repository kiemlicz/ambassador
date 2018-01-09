from __future__ import print_function
import sys
import json
import re
import argparse


JOB_RET = re.compile("salt/job/\d+/ret/\S+")
RUN_RET = re.compile("salt/run/\d+/ret")

parser = argparse.ArgumentParser(description='Scans event dump file.')
parser.add_argument('events', type=str, help='event list file')
args = parser.parse_args()


def _validate_jobs(event_list):
    failures = [e for e in event_list if not e["success"] or e["success"] and e["retcode"] != 0]
    for f in failures:
        print("Job: {}, on minion: {}, finished with error:\n{}\n"
              .format(f["fun"], f["id"], f["return"]).decode('string_escape'), file=sys.stderr)

    return len(failures) == 0


def _validate_runs(event_list):
    failures = [e for e in event_list if not e["success"]]
    for f in failures:
        print("Run: {}, from master, finished with error:\n{}\n"
              .format(f["fun"], f["return"]).decode('string_escape'), file=sys.stderr)

    return len(failures) == 0


with open(args.events) as f:
    lines = f.readlines()

all_events = [json.loads(l) for l in lines]
jobs = [e["data"] for e in all_events if JOB_RET.match(e["tag"])]
runs = [e["data"] for e in all_events if RUN_RET.match(e["tag"])]

jobs_ok = _validate_jobs(jobs)
runs_ok = _validate_runs(runs)

if not jobs_ok or not runs_ok:
    sys.exit(3)
