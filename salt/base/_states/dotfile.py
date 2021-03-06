import logging
import os


def managed(
    name,
    home_dir, 
    username,
    branch, 
    target, 
    identity=None,
    render=False, 
    override=False,
    saltenv='base'
    ):
    '''
    This state manages dotfiles: the 'name' repo is parsed and placed under 'home_dir'

    If template_dir contains images, binary files etc. they are simply omitted

    name
        dotfiles git repo url
    home_dir
        user home dir
    username
        user name
    branch
        dotfiles repo branch
    target
        where to put dotfiles
    identity
        Path to a private key to use for ssh URL
    render
        treat files in branch as templates and parse them before setting up dotiles
    override
        override existing dotfiles
    '''
    ret = {
        'name': name,
        'changes': {},
        'result': False,
        'comment': ''
    }
    log = logging.getLogger(__name__)

    # fixme add validation!
    # todo add context dict

    if not os.path.isabs(home_dir):
        return __utils__['common.fail'](ret, 'DOTFILE: home_dir \'{0}\' is not an absolute path'.format(home_dir))

    run_check_cmd_kwargs = {'runas': username}
    if 'shell' in __grains__:
        run_check_cmd_kwargs['shell'] = __grains__['shell']

    def clone_repo():
        tdir = __salt__['temp.dir'](prefix="tmpcfg-", parent="/tmp/")
        __salt__['file.chown'](tdir, username, username)
        log.debug("Temporary directory created: {0}".format(tdir))
        test_mode = __opts__['test']
        if test_mode:
            __opts__['test']=False
        #we clone in temporary location so never allow for test mode
        rdata = __states__['git.latest'](name=name, target=tdir, branch=branch, user=username, identity=identity)
        if test_mode:
            __opts__['test']=True
        if not rdata['result']:
            return __utils__['common.fail'](ret, "DOTFILE: Cloning dotfiles (templates) repo failed", comments=[rdata['comment']])
        return tdir

    def test_return(files_to_populate):
        ret['changes'] = {
            'old': 'Files that will be overriden: {0}'.format([e for e in files_to_populate if os.path.isfile(e)]),
            'new': 'Files that will be affected: {0}'.format(files_to_populate)
        }
        return __utils__['common.test'](ret, 'DOTFILE: (url: {0}, branch: {1}) will be applied'.format(name, branch))

    desired_branch = "refs/heads/{0}".format(branch)
    branches_dict = __salt__['git.remote_refs'](name, heads=True, tags=False, user=username, identity=identity, saltenv=saltenv)
    if not render and desired_branch in branches_dict:
        if __opts__['test']:
            log.debug("Checking out files (test mode) from: {0}, branch: {1}".format(name, branch))
            tempdir = clone_repo()
            if isinstance(tempdir, dict):
                return tempdir
            files = __salt__['cmd.run']("find {0} -path {0}/.git -prune -o -type f -print".format(tempdir)).splitlines()
            #override=True because dedicated branch in cfg repo is all or nothing
            populated_files = __salt__['populate.for_all'](tempdir, username, home_dir, files, True, saltenv)
            return test_return(populated_files)
        else:
            log.debug("Checking out files from: {0}, branch: {1}".format(name, branch))
            git_dir = "{0}/.cfg/".format(target)
            return_data = __states__['git.latest'](name=name, target=git_dir, user=username, bare=True, identity=identity)
            # no branch at this point as this is bare repository
            if not return_data['result']:
                return __utils__['common.fail'](ret, "DOTFILE: Cloning dotfiles repo failed", comments=[return_data['comment']])
            # backup previous files
            return_data = __states__['cmd.run']("mkdir -p {0}/.cfg.bak && "
                                                "git --git-dir={1} --work-tree={0} checkout {2} 2>&1 | sed -n 's/\(^[[:alnum:]]\)\?\s\+\(\.[[:alnum:]]\+\)/\\2/p'".format(target, git_dir, branch), runas=username)

            if return_data['changes']['retcode'] != 0:
                return __utils__['common.fail'](ret, "DOTFILE: Backup of previous dotfiles failed (git checkout)", comments=[return_data['changes']['stderr']])

            for f in return_data['changes']['stdout'].splitlines():
                ret = __states__['file.copy']("{}/.cfg.bak/".format(target), source=os.path.join(target, f), makedirs=True)
                if not ret['result']:
                    return __utils__['common.fail'](ret, "DOTFILE: Backup of previous dotfiles failed")
            for f in return_data['changes']['stdout'].splitlines():
                ret = __states__['file.absent'](os.path.join(target, f))
                if not ret['result']:
                    return __utils__['common.fail'](ret, "DOTFILE: Cannot remove backed files")

            # as this is bare repo -f must be used
            return_data = __states__['cmd.run']("git --git-dir={0} --work-tree={1} checkout -f {2}".format(git_dir, target, branch), runas=username)
            if return_data['changes']['retcode'] != 0:
                return __utils__['common.fail'](ret, "DOTFILE: Dotfiles checkout failed", comments=[return_data['changes']['stderr']])

            __states__['cmd.run']("git --git-dir={0} --work-tree={1} config --local status.showUntrackedFiles no".format(git_dir, target), runas=username)

            # todo better info: list exact old files backed, list exact new files
            ret['changes'].update({'dotfiles': {
                'old': 'saved in: {0}/.cfg.bak'.format(target),
                'new': 'populated using repo: {0}, branch: {1}'.format(name, branch)
            }})
            return __utils__['common.success'](ret, "DOTFILE: success without rendering")
    elif not render:
        log.error("DOTFILE: cannot find {} in {}".format(desired_branch, branches_dict.keys()))
        return __utils__['common.fail'](ret, "DOTFILE: dotfiles not found for: {} ({})".format(desired_branch, branches_dict.keys()), comments=["No changes"])

    if render:
        log.debug("Checking out templates from: {0}, branch: {1}".format(name, branch))
        tempdir = clone_repo()
        if isinstance(tempdir, dict):
           return tempdir
        files = __salt__['cmd.run']("find {0} -path {0}/.git -prune -o -type f -print".format(tempdir)).splitlines()
        populated_files = __salt__['populate.for_all'](tempdir, username, home_dir, files, override, saltenv)

        if __opts__['test']:
            return test_return(populated_files)

        if not populated_files:
            ret['comment'] = "Templates parsing success - no change"
            ret['changes'] = {}
        else:
            ret['comment'] = "Templates parsing success"
            ret['changes'].update({'populated files': {'old': '', 'new': populated_files}})

        return __utils__['common.success'](ret, "DOTFILE: success with render")

    return __utils__['common.fail'](ret, "DOTFILE: cannot setup dotfiles", comments=["No changes"])
