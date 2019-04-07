#!/usr/bin/env bash

tokens_count=$(kubeadm token list | wc -l)
# table with header, then entries...
if [ "$tokens_count"  -gt 1 ]; then
    kubeadm token list | awk '{if(NR==2) print $1}'
else
    kubeadm token create
fi
