repositories:
  {{ salt['grains.filter_by']({
    'default': {
      'list': [{
          'names': [
              "deb http://dl.google.com/linux/chrome/deb/ stable main"
          ],
          'file': '/etc/apt/sources.list.d/google-chrome.list',
          'key_url': 'https://dl.google.com/linux/linux_signing_key.pub'
      }]
     },
  }, grain='oscodename')|tojson }}