import os
import fileinput
import sys
import re
import logging
import salt.utils as utils


def manage_path(name, directory_inside, exports_file):
    '''
    add given variable with directories to system PATH

    name
        variable name
    directory_inside
        directory inside the 'name' variable-pointed directory
    exports_file
        linux systems file with 'export PATH' statement
    '''

    ret = {'name': name, 'changes': {}, 'result': False, 'comment': ''}
    log = logging.getLogger(__name__)

    if directory_inside is None:
        log.info("Unspecified directory_inside parameter - converting to empty string")
        directory_inside = ''

    if utils.is_windows():
        return __states__['win_path.exists'](os.path.join("%{0}%".format(name), directory_inside))
    else:
        #first check that this export is already present
        #only by trying to find the 'to_append' statement
        to_append = os.path.join("${0}".format(name), directory_inside) #$VAR/dir
        export_pattern = r"\s*export\s+PATH\s*=(.*)"
        export_at = None
        match = None
        for line in fileinput.input(exports_file):
            if re.search(re.escape(to_append), line) is not None:
                ret['result'] = True
                ret['changes'] = {}
                ret['comment'] = "Requested: {0} is already added to PATH".format(to_append)
                fileinput.close()
                return ret
            r = re.search(export_pattern, line)
            if r is not None and r.group(1).find("$PATH") != -1:
                #save last export statement
                match = r
                export_at = fileinput.lineno()
        fileinput.close()
        def export_statement(add=to_append):
            '''
            Adds export dir/dirs as leading export entries.
            So that it overrides existing entries.
            :return: export PATH statement
            '''
            return "export PATH={0}:$PATH".format(add)

        def test_return(changes):
            ret['result'] = None
            ret['comment'] = 'PATH will be modified'
            ret['changes'] = changes

        to_export = export_statement()

        if export_at is not None:
            for line in fileinput.input(exports_file, inplace=True):
                if fileinput.lineno() == export_at:
                    exports = [e for e in match.group(1).split(":") if e != "$PATH"]
                    exports.append(to_append)
                    to_export = export_statement(":".join(exports))
                    if __opts__['test']:
                        test_return({
                            'old': 'old export statement "export PATH={0}"'.format(match.group(1)),
                            'new': 'new export statement "{0}"'.format(to_export)
                        })
                        sys.stdout.write(line)
                    else:
                        ret['result'] = True
                        ret['changes'].update({'path export statement modified':
                                               {'old': [line],
                                                'new': [to_export]}})
                        ret['comment'] = "Requested: {0} was added to PATH".format(to_append)
                else:
                    sys.stdout.write(line)
            fileinput.close()

        if not __opts__['test']:
            with open(exports_file, "a") as f:
                f.write(to_export)
                if export_at is None:
                    ret['result'] = True
                    ret['changes'].update({'path export statement modified':
                                       {'old': '',
                                        'new': [to_export]}})
                    ret['comment'] = "New export line was added to: {0}".format(exports_file)
        elif export_at is None:
            test_return({
                'old': '',
                'new': 'export line: {0} will be added to: {1}'.format(to_export, exports_file)
            })
    return ret