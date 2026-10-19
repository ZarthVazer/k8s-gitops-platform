#!/usr/bin/env bash
# Installs Argo CD into the current kubectl context and hands the cluster over to Git.
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Cluster: $(kubectl config current-context)"

echo "==> Installing Argo CD"
kubectl apply --server-side --force-conflicts -k bootstrap/argocd

echo "==> Waiting for Argo CD to become ready"
kubectl -n argocd rollout status deploy/argocd-server --timeout=5m
kubectl -n argocd rollout status deploy/argocd-repo-server --timeout=5m
kubectl -n argocd rollout status statefulset/argocd-application-controller --timeout=5m

echo "==> Creating the root application (app-of-apps)"
kubectl apply -f bootstrap/root-app.yaml

cat <<'MSG'

Done. Argo CD now syncs everything from Git.

  UI:        kubectl -n argocd port-forward svc/argocd-server 8080:80
             open http://localhost:8080   (user: admin)
  Password:  kubectl -n argocd get secret argocd-initial-admin-secret \
               -o jsonpath='{.data.password}' | base64 -d; echo
  Status:    kubectl -n argocd get applications
MSG
