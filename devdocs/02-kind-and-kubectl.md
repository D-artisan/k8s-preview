# Kind and kubectl

## What Kind does

Kind runs Kubernetes nodes as Docker containers. In this project, the control-plane container is normally:

```text
k8s-preview-control-plane
```

Create the cluster:

```bash
make create-cluster
```

The Makefile pins Kubernetes to:

```text
kindest/node:v1.32.2
```

and uses:

```text
kubernetes/kind-config.yaml
```

## Why ports 30080 and 30443 exist

The Kind configuration maps Kubernetes node ports to your local machine:

```text
localhost:30080 -> Istio HTTP
localhost:30443 -> Istio HTTPS
```

Verify:

```bash
kubectl get svc istio-ingressgateway -n istio-system
curl -I http://localhost:30080
```

A `404` from `istio-envoy` can be healthy. It means Istio answered, but no VirtualService matched the request host/path.

## Stop, start and delete

Stop the existing cluster without deleting its state:

```bash
make stop-cluster
```

Start it again:

```bash
make start-cluster
```

Delete it completely:

```bash
make delete-cluster
```

The Makefile sets the control-plane Docker container restart policy to `no`, so it does not automatically restart across Docker/WSL sessions.

## Useful kubectl commands

Check the active cluster context:

```bash
kubectl config current-context
kubectl config get-contexts
```

For this repo, the expected context is:

```text
kind-k8s-preview
```

See resources:

```bash
kubectl get nodes
kubectl get namespaces
kubectl get all -A
```

Inspect a resource:

```bash
kubectl describe deployment preview-todo-app -n preview-2-todo-app
```

Read Pod logs:

```bash
kubectl logs <pod-name> -n preview-2-todo-app
```

Watch changes live:

```bash
kubectl get pods -n preview-2-todo-app -w
```
