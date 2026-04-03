#!/bin/bash

set -e
set -o pipefail

echo
echo "##############"
echo "# Kargo Demo #"
echo "##############"
echo

echo "========="
echo " Argo CD "
echo "========="
echo

(set -x; kubectl -n argocd get po)

read -rs

# Argo CD - Connect to UI
echo
echo "Argo CD UI URL : https://localhost:8080"

ARGO_CD_UI_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d | xargs)
echo "Argo CD UI password : ${ARGO_CD_UI_PASSWORD}"

read -rs

# Argo CD - ApplicationSet

echo
echo "[INFO] Create Argo CD ApplicationSet"
echo

cat <<EOF | kubectl -n argocd apply -f -
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: infrastructor-repo
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: ${HELM_REPOSITORY_URL}
  username: ${HELM_GITHUB_USERNAME}
  password: ${HELM_GITHUB_PAT}
EOF

(set -x; kubectl -n argocd apply -f ./argocd/configurations/infrastructor-appproject.yaml)
(set -x; envsubst < ./argocd/configurations/infrastructor-appset.yaml | kubectl -n argocd apply -f -)

# Production environment
echo
echo
echo "# Production environment"
echo "# Frontend: http://localhost:9300"
echo "# API : http://localhost:9301/info"

read -rs

# Kargo
echo
echo "======="
echo " Kargo "
echo "======="
echo

(set -x; kubectl -n kargo get po)

read -rs

echo
echo "Kargo UI URL : https://localhost:8081"

sleep 1

kargo login https://localhost:8081 \
  --admin \
  --password admin \
  --insecure-skip-tls-verify

read -rs

# Kargo configuration
echo
echo "[INFO] Setup Kargo"
echo

(set -x; kubectl apply -f ./kargo/configurations/infrastructor-project.yaml)

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: infrastructor-repo
  namespace: infrastructor
  labels:
    kargo.akuity.io/cred-type: git
stringData:
  repoURL: ${HELM_REPOSITORY_URL}
  username: ${HELM_GITHUB_USERNAME}
  password: ${HELM_GITHUB_PAT}
EOF

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: infrastructor-images
  namespace: kargo-shared-resources
  labels:
    kargo.akuity.io/cred-type: image
stringData:
  repoURL: ${IMAGE_REGISTRY_URL}
  repoURLIsRegex: "true"
  username: x-access-token
  password: ${IMAGE_REGISTRY_GITHUB_PAT}
EOF

read -rs

# Kargo Stages
echo
echo "[INFO] Create Stages"
echo
(set -x; kargo apply -f ./kargo/configurations/infrastructor-warehouse.yaml)
(set -x; envsubst < ./kargo/configurations/infrastructor-tst-stage.yaml | kubectl -n infrastructor apply -f -)
(set -x; envsubst < ./kargo/configurations/infrastructor-qua-stage.yaml | kubectl -n infrastructor apply -f -)
(set -x; envsubst < ./kargo/configurations/infrastructor-prd-stage.yaml | kubectl -n infrastructor apply -f -)

read -rs

# Test environment
echo
echo
echo "# Test environment"
echo "# Frontend: http://localhost:9100"
echo "# API : http://localhost:9101/info"

echo 
echo "# Stages"
(set -x; kargo get stages --project infrastructor)
echo
echo "# Promotions"
(set -x; kargo get promotions --project infrastructor)
echo

read -rs

# Quality environment
echo
echo
echo "# Quality environment"
echo "# Frontend: http://localhost:9200"
echo "# API : http://localhost:9201/info"

echo 
echo "# Stages"
(set -x; kargo get stages --project infrastructor)
echo
echo "# Promotions"
(set -x; kargo get promotions --project infrastructor)
echo

read -rs

# Production environment
echo
echo
echo "# Production environment"
echo "# Frontend: http://localhost:9300"
echo "# API : http://localhost:9301/info"

echo 
echo "# Stages"
(set -x; kargo get stages --project infrastructor)
echo
echo "# Promotions"
(set -x; kargo get promotions --project infrastructor)
echo

read -rs
