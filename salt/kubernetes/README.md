# Kubernetes
Deploys and configures the Kubernetes Nodes.  

## Available states
 - [`kubernetes.master`](#kubernetesmaster)
 - [`kubernetes.worker`](#kubernetesworker)
 - [`kubernetes.helm`](#kuberneteshelm)

## Usage
Some prerequisites must be met first (pre 3005 version):
 - _Salt Minion_ config must contain:
```
use_superseded:
  - module.run
```
 - if you want to receive `KUBECONFIG` on the _Salt Master_, set: `file_recv: True` in _Salt Master_ config

 - _Salt Master_ config must contain (if using Kubernetes multi-master setup):
```
peer:
  .*:
    - x509.sign_remote_certificate
```

1. Set pillar on the Salt Master:
Specify the Pillar for master and worker nodes, CIDR of the Kubernetes Nodes k8s interface (for some network plugins you need to specify CIDR as well):
```
kubernetes:
    nodes:
        cidr: 10.0.0.0/8
        masters:
           - k8s1
           - k8s2
        workers:
           - k8s3
           - k8s4

# must be added if Salt controlled CA
x509_signing_policies:
  kubernetes:
    - minions: 'k8s*'
    - signing_private_key: /etc/kubernetes/pki/ca.key
    - signing_cert: /etc/kubernetes/pki/ca.crt
    - basicConstraints: "critical CA:false"
    - subjectKeyIdentifier: hash
    - authorityKeyIdentifier: keyid,issuer:always
    - days_valid: 365
```
2. `salt-run state.orchestrate kubernetes._orchestrate.cluster saltenv=base pillar='{"kubernetes": {"nodes": {"masters": [k8s1], "workers": [k8s2, k8s3]}}}'`

### `kubernetes.master`
Setup Kubernetes master node

#### Example pillar
```
kubernetes:
  network:
    provider: flannel
    cidr: "10.244.0.0/16"
  master:
    isolate: True
    reset: False          # whether issue kubeadm reset beforehand 
    upload_config: True   # whether to push config file to salt-master
```

### `kubernetes.worker`
Setup Kubernetes worker node

#### Example pillar

### `kubernetes.helm`
Setup Kubernetes worker node

#### Example pillar
```
#kubernetes may require concrete docker version, set with:
#docker:
#    version: "18.06.1~ce~3-0~ubuntu"
#    version: "18.06.1~ce~3-0~debian"
kubernetes:
  network:
    provider: flannel
    cidr: "10.244.0.0/16"
  master:
    isolate: True
  nodes:
    masters:
      - k8s1
    workers:
      - k8s2
      - k8s3
```

# Provisioning PODs
In this approach it is assumed that application images are already prepared. _Salt_ is used to orchestrate the application logic that would not be possible with Kubernetes tooling only. 
Kubernetes takes care of POD lifecycle management "only".  
Applications that require administrative work can still benefit from _Salt_.  
In order to leverage _Salt_ capabilities to orchestrate Kubernetes PODs following deployment strategies exists:  

_Salt Master_
 1. Deployed in separate VM outside of Kubernetes cluster.  
 2. Deployed in POD

_Salt Minion_
 1. Deployed as a _DaemonSet_ when using [`docker_events`](https://docs.saltstack.com/en/latest/ref/engines/all/salt.engines.docker_events.html) or as _Deployment_ when using [`k8s_events`](https://github.com/kiemlicz/ambassador/blob/master/salt/base/_engines/k8s_events.py)
 2. Deployed directly on Kubernetes Nodes
 
| Minion\Master | Separate VM | POD |
| - | - | - |
| **POD** | The VM must be able to route traffic to k8s PODs. Minions must have k8s Node's `docker.sock` mounted | Minions must have Node's `docker.sock` mounted |
| **K8s Nodes** | Only k8s Nodes - VM connectivity must be possible. It must be possible to install _Salt Minion_ on k8s Nodes | Node-POD communication must be possible. It must be possible to install _Salt Minion_ on k8s Nodes | 


# References
1. https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/
