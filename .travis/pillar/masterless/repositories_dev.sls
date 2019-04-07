{% set os = salt['grains.get']('lsb_distrib_id') %}
{% set dist_codename = salt['grains.get']('lsb_distrib_codename') %}

repositories:
  {{ salt['grains.filter_by']({
    'default': {
      'sources_list_location': '/etc/apt/sources.list',
      'list':[],
      'preferences': [],
    },
    'RedHat': {
      'list': []
    },
  }, merge=salt['grains.filter_by']({
    'sid': {
      'list': [{
                   'file': '/etc/apt/sources.list.d/erlang.list',
                   'names': ["deb http://packages.erlang-solutions.com/" + os.lower() +  " stretch contrib"],
                   'key_url': "http://packages.erlang-solutions.com/" + os.lower() + "/erlang_solutions.asc",
                 }],
      'preferences': [{
                        'file': '/etc/apt/preferences.d/erlang.pref',
                        'pin': 'release o=Erlang Solutions Ltd.',
                        'priority': '999'
                      }]
    },
    'stretch': {
      'list': [{
                   'file': '/etc/apt/sources.list.d/erlang.list',
                   'names': ["deb http://packages.erlang-solutions.com/" + os.lower() +  " " + dist_codename + " contrib"],
                   'key_url': "http://packages.erlang-solutions.com/" + os.lower() + "/erlang_solutions.asc",
                }
      ],
      'preferences': [ {
                          'file': '/etc/apt/preferences.d/erlang.pref',
                          'pin': 'release o=Erlang Solutions Ltd.',
                          'priority': '999'
                        }]
    },
  }, grain='oscodename'))|tojson }}
