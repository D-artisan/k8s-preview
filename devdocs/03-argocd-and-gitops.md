# Argo CD and GitOps

## What GitOps means here

Git is the desired state. Argo CD continuously compares what is stored in Git with what exists in Kubernetes.

In this project, GitHub Actions creates a branch such as:

```text
preview-2
```

That branch contains the rendered Kubernetes manifest for PR 2.

Argo CD reads that branch and applies the resources to the local Kind cluster.

## ApplicationSet vs Application

An `Application` represents one deployable Argo CD workload.

An `ApplicationSet` is a generator that creates Applications automatically.

This project installs one ApplicationSet:

```text
todo-app-preview-environment
```

It watches GitHub pull requests with the `preview` label and generates Applications such as:

```text
todo-app-preview-2
todo-app-preview-3
```

Inspect them:

```bash
kubectl get applicationsets -n argocd
kubectl get applications -n argocd
```

## Why an open PR matters

The generator is configured to discover open pull requests. GitHub Actions adds the `preview` label after the build/render workflow succeeds.

The important chain is:

```text
open PR
  -> GitHub Actions succeeds
  -> preview label added
  -> preview-<PR> branch created
  -> ApplicationSet detects PR
  -> Application created
```

When the PR is closed or merged, the generated Application disappears.

## Install Argo CD

```bash
make install-argocd
```

Verify:

```bash
kubectl get pods -n argocd
kubectl get crd applicationsets.argoproj.io
```

Wait for the ApplicationSet controller:

```bash
kubectl rollout status deployment/argocd-applicationset-controller   -n argocd   --timeout=180s
```

## Create this project's ApplicationSet

```bash
make add-argocd-applicationset
```

For this fork enter:

```text
OWNER=D-artisan
REPO=k8s-preview
```

The generated configuration points Argo CD to:

```text
https://github.com/D-artisan/k8s-preview.git
```

and to branches such as:

```text
preview-2
```

## Access the Argo CD UI

```bash
make access-argocd
```

The local port forward is:

```text
localhost:8085 -> argocd-server Service -> Argo CD server Pod
```

Open:

```text
https://localhost:8085
```

The browser may warn about the local certificate.

## Sync status vs health

These are different ideas.

`Synced` means Kubernetes matches Git.

`OutOfSync` means Git and the cluster differ.

`Healthy` means the deployed resources are operating normally.

`Missing` often means Argo CD expected resources that were not successfully created.

A generated Application can therefore exist while its synchronization still fails.

## Find the exact sync error

```bash
kubectl -n argocd get application todo-app-preview-2   -o jsonpath='{.status.operationState.message}{"\n"}'
```

Show Application conditions:

```bash
kubectl -n argocd get application todo-app-preview-2   -o jsonpath='{range .status.conditions[*]}{.type}{": "}{.message}{"\n"}{end}'
```

## Hard refresh and retry

If a CRD was installed after Argo CD already attempted the sync:

```bash
kubectl annotate application todo-app-preview-2   -n argocd   argocd.argoproj.io/refresh=hard   --overwrite
```

Then use `REFRESH -> Hard Refresh` and `SYNC -> SYNCHRONIZE` in the UI.

You can also request a sync from kubectl:

```bash
kubectl patch application todo-app-preview-2   -n argocd   --type merge   -p '{"operation":{"sync":{"prune":true}}}'
```

## Mental model

```text
ApplicationSet = factory
Application    = one generated deployment definition
Git branch     = desired state
Kubernetes     = actual state
Argo CD        = reconciler between desired and actual state
```
