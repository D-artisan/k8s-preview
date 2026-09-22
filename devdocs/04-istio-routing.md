# Istio Routing in This Project

## What Istio is doing here

Istio provides the entry point and routing rules for each preview environment.

The flow is:

```text
Browser
  |
  v
localhost:30080
  |
  v
Istio ingress gateway
  |
  v
VirtualService
  |
  +--> KEDA HTTP interceptor
  |
  v
preview-todo-app Service
  |
  v
application Pod
```

## Install Istio

```bash
make enable-istio
make create-istio-gateway
```

Verify:

```bash
kubectl get pods -n istio-system
kubectl get svc istio-ingressgateway -n istio-system
kubectl get gateway -n istio-system
```

## Why localhost:30080 can return 404

This command:

```bash
curl -I http://localhost:30080
```

may return:

```text
HTTP/1.1 404 Not Found
server: istio-envoy
```

That proves the gateway is reachable. The 404 occurs because preview routing is host-based and the plain `localhost` host does not match a preview VirtualService.

## VirtualService

A VirtualService tells Istio how matching traffic should be routed.

For PR 2 this project generates hostnames similar to:

```text
todo-2-pr.127.0.0.1.sslip.io
todo-2-pr-<commit>.127.0.0.1.sslip.io
```

Inspect the generated rule:

```bash
kubectl get virtualservice -n preview-2-todo-app
kubectl describe virtualservice todo -n preview-2-todo-app
```

## DestinationRule

A DestinationRule defines subsets of a Service. This project uses the Git commit version label so the commit-specific URL can route to the exact application version.

```bash
kubectl get destinationrule -n preview-2-todo-app
kubectl describe destinationrule todo -n preview-2-todo-app
```

## sslip.io

A hostname ending in `127.0.0.1.sslip.io` resolves to `127.0.0.1`.

That lets each PR have a unique hostname while still reaching the local Kind cluster.
