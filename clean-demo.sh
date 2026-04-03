#!/bin/bash

set -e
set -o pipefail

echo
echo "[INFO] Delete Argo CD configurations"
echo

(set -x; kubectl -n argocd delete -f ./argocd/configurations/infrastructor-appset.yaml --ignore-not-found --force --grace-period 0)

(set -x; kubectl -n argocd delete application infrastructor-tst --ignore-not-found --force --grace-period 0)
(set -x; kubectl -n argocd delete application infrastructor-qua --ignore-not-found --force --grace-period 0)
(set -x; kubectl -n argocd delete application infrastructor-prd --ignore-not-found --force --grace-period 0)

sleep 10
(set -x; kubectl -n argocd delete -f ./argocd/configurations/infrastructor-appproject.yaml --ignore-not-found --force --grace-period 0)
(set -x; kubectl -n argocd delete secret infrastructor-repo --ignore-not-found --force --grace-period 0)

(set -x; kubectl delete ns infrastructor-tst --ignore-not-found --force --grace-period 0)
(set -x; kubectl delete ns infrastructor-qua --ignore-not-found --force --grace-period 0)
(set -x; kubectl delete ns infrastructor-prd --ignore-not-found --force --grace-period 0)

echo
echo "[INFO] Delete Kargo project"
echo

(set -x; kubectl delete projects.kargo.akuity.io infrastructor --ignore-not-found --force --grace-period 0)
(set -x; kubectl -n infrastructor delete secret infrastructor-repo --ignore-not-found --force --grace-period 0)

echo
echo "[INFO] Delete Kargo Stages"
echo

(set -x; kubectl delete -f ./kargo/configurations/infrastructor-prd-stage.yaml --ignore-not-found --force --grace-period 0)
(set -x; kubectl delete -f ./kargo/configurations/infrastructor-qua-stage.yaml --ignore-not-found --force --grace-period 0)
(set -x; kubectl delete -f ./kargo/configurations/infrastructor-tst-stage.yaml --ignore-not-found --force --grace-period 0)
(set -x; kubectl delete -f ./kargo/configurations/infrastructor-warehouse.yaml --ignore-not-found --force --grace-period 0)
