kubernetes:
  kubeconfig:
    - ca_cert: "/path/to/ca.cert"
      client_cert: "/path/to/client.cert"
      client_key: "/path/to/client.key"
      server: "https://192.168.1.2:8443"
      user: minikube
      cluster: minikube
      context: minikube
