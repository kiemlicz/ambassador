import salt.runner


def no_jobs_running(minion):
    opts = __opts__.copy()
    r = salt.runner.RunnerClient(opts)
    o = r.cmd("jobs.active")

    if not o:
        __jid_event__.fire_event({'data': {}}, 'progress')
