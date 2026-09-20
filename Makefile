CLUSTER_NAME ?= k8s-preview
KUBE_CONTEXT ?= kind-$(CLUSTER_NAME)
KIND_CONFIG ?= kubernetes/kind-config.yaml
ISTIO_NAMESPACE ?= istio-system

GIT_REV := $(shell git rev-parse --short HEAD)
export GIT_REV

.PHONY: build
build:
	@echo "Building with GIT_REV=$(GIT_REV)"
	CI=true skaffold build

.PHONY: render-preview
render-preview:
	@if [ -z "$(GIT_PR_NUMBER)" ]; then \
		echo "Error: GIT_PR_NUMBER is required. Usage: make render-preview GIT_PR_NUMBER=123"; \
		exit 1; \
	fi
	@echo "Rendering preview manifests with GIT_PR_NUMBER=$(GIT_PR_NUMBER) and GIT_REV=$(GIT_REV)"
	mkdir -p manifests/preview/$(GIT_PR_NUMBER)
	CI=true TIER=preview skaffold render --digest-source=remote -o manifests/preview/$(GIT_PR_NUMBER)/manifests.yaml

.PHONY: render-preview-test
render-preview-test:
	GIT_PR_NUMBER=123
	@echo "Rendering preview manifests with GIT_PR_NUMBER=$(GIT_PR_NUMBER) and GIT_REV=$(GIT_REV)"
	CI=true TIER=preview skaffold render

.PHONY: create-cluster
create-cluster:
	@command -v kind >/dev/null 2>&1 || { echo "kind is required: https://kind.sigs.k8s.io/docs/user/quick-start/"; exit 1; }
	kind create cluster --name $(CLUSTER_NAME) --config $(KIND_CONFIG)
	@docker update --restart=no $(CLUSTER_NAME)-control-plane >/dev/null
	kubectl config use-context $(KUBE_CONTEXT)
	kubectl wait --for=condition=Ready node --all --timeout=120s
	@echo "Kind cluster '$(CLUSTER_NAME)' is ready."

.PHONY: stop-cluster
stop-cluster:
	docker stop $(CLUSTER_NAME)-control-plane

.PHONY: start-cluster
start-cluster:
	docker start $(CLUSTER_NAME)-control-plane
	kubectl config use-context $(KUBE_CONTEXT)
	@for i in $$(seq 1 60); do kubectl get nodes >/dev/null 2>&1 && exit 0; sleep 2; done; echo "Timed out waiting for Kubernetes API"; exit 1

.PHONY: delete-cluster
delete-cluster:
	kind delete cluster --name $(CLUSTER_NAME)

.PHONY: enable-istio
enable-istio:
	@command -v istioctl >/dev/null 2>&1 || { echo "istioctl is required: https://istio.io/latest/docs/setup/getting-started/"; exit 1; }
	istioctl install --set profile=default -y
	kubectl rollout status deployment/istiod -n $(ISTIO_NAMESPACE) --timeout=180s
	kubectl patch svc istio-ingressgateway -n $(ISTIO_NAMESPACE) --type=merge -p '{"spec":{"type":"NodePort","ports":[{"name":"status-port","port":15021,"protocol":"TCP","targetPort":15021,"nodePort":30021},{"name":"http2","port":80,"protocol":"TCP","targetPort":8080,"nodePort":30080},{"name":"https","port":443,"protocol":"TCP","targetPort":8443,"nodePort":30443}]}}'
	kubectl rollout status deployment/istio-ingressgateway -n $(ISTIO_NAMESPACE) --timeout=180s
	@echo "Istio ingress is available at http://localhost:30080"

.PHONY: create-istio-gateway
create-istio-gateway:
	kubectl apply -f kubernetes/istio/gateway.yaml

.PHONY: install-keda
install-keda:
	helm repo add kedacore https://kedacore.github.io/charts
	helm repo update
	helm install keda kedacore/keda --namespace keda --create-namespace

.PHONY: install-keda-http-addon
install-keda-http-addon:
	helm repo add kedacore https://kedacore.github.io/charts
	helm repo update
	helm install http-add-on kedacore/keda-add-ons-http --namespace keda-http-addon --create-namespace

.PHONY: install-argocd
install-argocd:
	kubectl create namespace argocd
	kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

.PHONY: access-argocd
access-argocd:
	@echo "Username: admin"
	@echo "Admin password:"
	@kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
	@echo ""
	@echo "Check the ArgoCD UI at http://localhost:8080"
	kubectl port-forward svc/argocd-server -n argocd 8080:443

.PHONY: add-argocd-applicationset
add-argocd-applicationset:
	@echo "Adding ArgoCD Preview ApplicationSet"
	@echo "Please provide the Github username (e.g. araminian):"; \
	read OWNER; \
	echo "Please provide the repository name (e.g. k8s-preview):"; \
	read REPO; \
	echo "OWNER=$$OWNER"; \
	echo "REPO=$$REPO"; \
	export OWNER REPO; \
	envsubst < kubernetes/argocd/applicationSet.yaml | kubectl apply -f -
