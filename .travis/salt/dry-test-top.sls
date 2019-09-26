#!py


def run():
  def _merge(src, dst):
    for k, v in src.items():
      if isinstance(v, dict):
        _merge(v, dst.setdefault(k, {}))
      elif isinstance(v, list):
        dst.setdefault(k, []).extend(v)
      else:
        dst[k] = v
    return dst


  base = {
    '*': [
      "os",
      "samba",
      "mail",
      "minion",
      "minion.upgrade",
    ],
    'G@os_family:Debian': [
      "os.pkgs.unattended"
    ],
    'not G@os:Windows and not G@virtual_subtype:Docker': [
      "lxc"
    ],
    'not G@os:Windows': [
      "users"
    ]
  }

  dev = {
    '*': [
      "java",
      "scala",
      "gradle",
      "maven",
      "sbt",
      "erlang",
      "rebar",
      "intellij",
      "robomongo",
      "gatling",
      "grafana",
      "virtualbox",
      "projects",
      "influxdb",
      "redis.client",
      "mongodb.client",
      "redis.server",
      "docker",
      "docker.compose",
    ],
    'I@mongodb:setup_type:cluster': [
      "mongodb.server.cluster"
    ],
    'I@mongodb:setup_type:single': [
      "mongodb.server.single"
    ]
  }

  server = {
    'not G@os:Windows': [
      "keepalived",
      "lvs.director",
      "lvs.realserver",
      "kvm",
      "kubernetes.client",
      "kubernetes.minikube",
      "kubernetes.master",
      "kubernetes.worker",
      "kubernetes.helm",
      "vagrant"
    ]
  }

  top = {}
  top['base'] = base
  top['dev'] = _merge(base, dev)
  top['server'] = _merge(dev, server)
  return top