# Kubernetes Fundamentals in This Project

## 1. Cluster

A Kubernetes cluster is the environment that runs Kubernetes workloads.

This project creates a local cluster with Kind:

```bash
make create-cluster
```

The cluster name is:

```text
k8s-preview
```

Check it:

```bash
kind get clusters
kubectl cluster-info
```

## 2. kubectl client vs cluster version

`kubectl` is the CLI installed on your machine. The Kubernetes server runs inside the cluster. They can have different versions.

```bash
kubectl version
```

In this repo, Kind is pinned to Kubernetes `v1.32.2` through:

```make
KIND_IMAGE ?= kindest/node:v1.32.2
```

The cluster version mattered when installing Istio because newer Istio releases require a sufficiently recent Kubernetes server.

## 3. Namespace

A namespace is a logical boundary used to group Kubernetes resources.

Every preview PR gets its own namespace:

```text
preview-<PR_NUMBER>-todo-app
```

For PR 2:

```bash
kubectl get namespace preview-2-todo-app
kubectl get all -n preview-2-todo-app
```

Do not confuse the Argo CD Application name:

```text
todo-app-preview-2
```

with the Kubernetes namespace:

```text
preview-2-todo-app
```

## 4. Deployment, ReplicaSet and Pod

The relationship is:

```text
Deployment
   |
   v
ReplicaSet
   |
   v
Pod
   |
   v
Container
```

The Deployment describes the desired state of the application. Kubernetes creates a ReplicaSet, and the ReplicaSet creates the required Pods.

In this project:

```bash
kubectl get deployment -n preview-2-todo-app
kubectl get rs -n preview-2-todo-app
kubectl get pods -n preview-2-todo-app
```

KEDA may intentionally scale the Deployment to zero, so seeing no Pods can be correct.

## 5. Service

Pods are replaceable and their IP addresses can change. A Service gives the application a stable network endpoint.

This project creates:

```text
service/preview-todo-app
```

Inspect it:

```bash
kubectl get svc -n preview-2-todo-app
kubectl describe svc preview-todo-app -n preview-2-todo-app
```

The Service listens on port 80 and forwards to the application container.

## 6. Custom Resource Definitions

Kubernetes has built-in resource types such as Deployment and Service. Tools such as Istio, Argo CD and KEDA add new resource types through Custom Resource Definitions, or CRDs.

Examples used here:

```text
ApplicationSet
Application
VirtualService
DestinationRule
HTTPScaledObject
```

Check whether Kubernetes knows a resource type:

```bash
kubectl api-resources | grep -i application
kubectl api-resources --api-group=http.keda.sh
kubectl get crd
```

If Argo CD tries to deploy a custom resource before its CRD exists, synchronization fails.
