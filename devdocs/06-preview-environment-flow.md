# End-to-End Preview Environment Flow

This is the complete lifecycle of one change.

## 1. Create a feature branch

```bash
git checkout main
git pull origin main
git checkout -b feature/preview-demo
```

Make a code change, then:

```bash
git add .
git commit -m "Test preview environment"
git push -u origin feature/preview-demo
```

## 2. Open the PR in this fork

```bash
gh pr create   --repo D-artisan/k8s-preview   --base main   --head feature/preview-demo   --title "Test preview environment"
```

Do not target the upstream `araminian/k8s-preview` repository when testing this local setup. The ApplicationSet is configured to watch this fork.

Keep the PR open while testing.

## 3. GitHub Actions runs

The workflow only runs on pull request events, not ordinary pushes to `main`.

Check:

```bash
gh run list   --repo D-artisan/k8s-preview   --workflow ci-preview   --limit 5
```

The workflow:

1. builds the Docker image,
2. pushes it to Docker Hub,
3. renders the Kubernetes YAML,
4. writes that YAML to `preview-<PR_NUMBER>`,
5. adds the `preview` label to the PR,
6. posts preview URLs.

Verify the PR:

```bash
gh pr view   --repo D-artisan/k8s-preview   --json number,state,labels,headRefName,baseRefName
```

## 4. ApplicationSet discovers the PR

```bash
kubectl get applicationsets -n argocd
kubectl get applications -n argocd -w
```

Allow up to roughly 90 seconds because the generator polls GitHub.

For PR 2, the generated Application is:

```text
todo-app-preview-2
```

## 5. Argo CD syncs the preview branch

Argo CD reads:

```text
preview-2
```

and creates resources in:

```text
preview-2-todo-app
```

Check:

```bash
kubectl get namespace preview-2-todo-app
kubectl get all -n preview-2-todo-app
kubectl get httpscaledobject -n preview-2-todo-app
```

## 6. KEDA may scale Pods to zero

A Deployment and Service can exist while there are no Pods:

```bash
kubectl get pods -n preview-2-todo-app
```

That is expected when the preview is idle.

## 7. Access the preview

Use the PR URL posted by GitHub Actions. The hostname is important because Istio routes by host.

Watch KEDA wake the application:

```bash
kubectl get pods -n preview-2-todo-app -w
```

## 8. Close or merge the PR

Closing the PR causes the preview lifecycle to end. The ApplicationSet stops generating the Application and the workflow removes the temporary preview branch.
