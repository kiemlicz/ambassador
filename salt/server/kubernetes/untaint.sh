#!/usr/bin/env bash

if [ -z $1 ]; then
    >&2 echo "Minion ID required"
    exit 1
fi

kubectl get nodes -o go-template='{{range $item := .items}}{{with $nodename := $item.metadata.name}}{{range $taint := $item.spec.taints}}{{if and (eq $taint.key "node-role.kubernetes.io/master") (eq $taint.effect "NoSchedule")}}{{printf "%s\n" $nodename}}{{end}}{{end}}{{end}}{{end}}' | grep -q $1
if [ $? -eq 0 ]; then
    kubectl taint nodes --all node-role.kubernetes.io/master-
fi
