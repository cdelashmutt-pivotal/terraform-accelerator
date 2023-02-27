# Provision AKS with TAP

## Setup
This repository contains your terraform scripts for deploying an AKS cluster with TAP.  You could manage deploying this yourself, or you can add a reference to this GitOps repo that is monitored by the Platform Ops cluster for automatic management.

Add these manifests to your central cluster:
```
apiVersion: v1
kind: Namespace
metadata:
  name: NAMESPACE
---
apiVersion: source.toolkit.fluxcd.io/v1beta1
kind: GitRepository
metadata:
  name: git-terraform
  namespace: NAMESPACE
spec:
  interval: 30s
  url: https://github.com/cdelashmutt-pivotal/terraform-accelerator
  ref:
    branch: main
---
apiVersion: infra.contrib.fluxcd.io/v1alpha1
kind: Terraform
metadata:
  name: clusters
  namespace: NAMESPACE
spec:
  interval: 1m
  path: ./terraform
  sourceRef:
    kind: GitRepository
    name: git-terraform
    namespace: NAMESPACE
```