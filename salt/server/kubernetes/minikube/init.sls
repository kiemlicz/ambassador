{% from "kubernetes/minikube/map.jinja" import kubernetes with context %}


include:
  - docker
  - kubernetes.minikube.minikube_bin
  - kubernetes.minikube.{{ kubernetes.minikube.driver }}
  - kubernetes.minikube.minikube_setup
