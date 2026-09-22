# Developer Learning Guides

This directory explains the core platform concepts used by this project in beginner-friendly terms.

Use the guides in this order:

1. [Kubernetes fundamentals](01-kubernetes-fundamentals.md)
2. [Kind and kubectl](02-kind-and-kubectl.md)
3. [Argo CD and GitOps](03-argocd-and-gitops.md)
4. [Istio routing](04-istio-routing.md)
5. [KEDA scaling](05-keda-scaling.md)
6. [End-to-end preview flow](06-preview-environment-flow.md)
7. [Troubleshooting runbook](07-troubleshooting.md)

The goal is to learn the concepts by observing this repository while it is running. Each guide points to the actual resources and commands used here.

## Project map

```text
Feature branch
   |
   v
Pull Request
   |
   v
GitHub Actions
   |-- builds/pushes Docker image
   |-- renders Kubernetes manifests
   |-- creates preview-<PR_NUMBER> branch
   |-- adds preview label
   v
Argo CD ApplicationSet
   |
   v
Argo CD Application
   |
   v
Kubernetes namespace: preview-<PR_NUMBER>-todo-app
   |
   +-- Deployment
   +-- Service
   +-- HTTPScaledObject
   +-- VirtualService
   +-- DestinationRule
   |
   v
Istio + KEDA -> preview application
```
