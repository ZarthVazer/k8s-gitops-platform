.PHONY: cluster bootstrap status ui password validate destroy

KIND_CLUSTER ?= gitops

cluster:      ## Create a local kind cluster (skip if you use Docker Desktop Kubernetes)
	kind create cluster --name $(KIND_CLUSTER)

bootstrap:    ## Install Argo CD and hand the cluster over to Git
	bash scripts/bootstrap.sh

status:       ## Show all Argo CD applications
	kubectl -n argocd get applications

ui:           ## Open the Argo CD UI on http://localhost:8080
	kubectl -n argocd port-forward svc/argocd-server 8080:80

password:     ## Print the initial admin password
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo

validate:     ## Build and validate all manifests locally
	@for d in $$(find . -name kustomization.yaml -not -path './.git/*' -exec dirname {} \;); do \
	  echo "== $$d"; kustomize build $$d | kubeconform -strict -summary -ignore-missing-schemas; done

destroy:      ## Delete the local kind cluster
	kind delete cluster --name $(KIND_CLUSTER)
