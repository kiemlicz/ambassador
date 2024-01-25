#!jinja|stringpy

import json

{% from "mongodb/server/cluster/map.jinja" import mongodb with context %}

# according to https://docs.mongodb.com/manual/tutorial/deploy-replica-set/
# this state must execute on one minion only
# this state run on existing replica will reconfigure it
def run():
  def get_ip(id):
      # it is impossible to use ip.jinja in stringpy (id is not known in jinja renderer)
      return salt['mine.get'](id, 'network.ip_addrs').values()[0][0]

  mongodb = {{ mongodb|json }}
  master = mongodb["master"]
  master_ip = master.get("ip", get_ip(master['id']))
  state = {}
  members = []

  for i in xrange(0, len(mongodb['replicas'])):
    replica = mongodb['replicas'][i]
    replica_ip = replica.get("ip", get_ip(replica['id']))
    members.append({
      '_id': i,
      'host': "{}:{}".format(replica_ip, replica['port'])
    })

  replica_config = json.dumps({
    '_id': master['replica_name'],
    'members': members
  })

  state['mongodb_initiate_replica_set'] = {
    'cmd.run': [
      { 'name': "mongo --host {} --port {} --eval 'rs.initiate({})'".format(master_ip, master['port'], replica_config) },
      { 'onlyif': "mongo --host {} --port {} --eval 'rs.status()' | grep 'errmsg'".format(master_ip, master['port']) }
    ]
  }

  state['mongodb_reconfig_replica_set'] = {
    'cmd.run': [
      { 'name': "mongo --host {} --port {} --eval 'rs.reconfig({})'".format(master_ip, master['port'], replica_config) },
      { 'unless': "mongo --host {} --port {} --eval 'rs.status()' | grep 'errmsg'".format(master_ip, master['port']) }
    ]
  }

  return state
