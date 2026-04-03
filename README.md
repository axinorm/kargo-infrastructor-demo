# Kargo demo with Infrastructor

## Prerequisites

* **Podman** or another **container runtime**: To run containers
* **kind**: To quickly bootstrap and run a Kubernetes cluster

## Setup demo

### Download Kargo binary

The Kargo binary is required for the demo in order to deploy configuration objects such as ``Stage``.

You can download it with the following commands:

```sh
KARGO_VERSION=1.9.5
ARCH=$(uname -m)
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
[ "$ARCH" = "x86_64" ] && ARCH=amd64
curl -L -o ./bin/kargo https://github.com/akuity/kargo/releases/download/v${KARGO_VERSION}/kargo-${OS}-${ARCH}
chmod +x ./bin/kargo
```

Don't forget to add the ``./bin`` path in your global **PATH** variable. For example: ``export PATH=$PATH:$PWD/bin``.

### Infrastructor images

The Infrastructor applications (frontend and API) are private to protect source code but you can use your own images by creating a dedicated repository and updating the image references in the Helm chart.

### Helm package

The Helm package must be pushed into a **new** Git repository.

To do so, you need to create a Git repository inside the ``helm`` folder and push it to a dedicated GitHub repository.

### Environment variables

Add these variables to the ``.envrc`` file or in your shell environment, and generate two tokens:

* The first one to pull images from private ghcr repository, this token needs to be *classic* due to [some limitations](https://github.com/orgs/community/discussions/38467), with *read:packages* permission;

* The second for Kargo, it can be a fine-grained token with *Contents: Read and write*, *Metadata: Read-only* and *Pull requests: Read and write* repository access to let Kargo write changes to Git and create Pull requests.

```bash
# Kind
export KIND_CLUSTER_NAME= # Kind cluster name

# Kargo
export HELM_REPOSITORY_URL=  # Repository with the Helm chart for Kargo
export HELM_GITHUB_USERNAME= # GitHub username
export HELM_GITHUB_PAT=      # Personal Access Token for Kargo tasks

# Images
export IMAGE_REGISTRY_URL=        # GHCR.io URL
export IMAGE_REGISTRY_GITHUB_PAT= # Personal Access Token to pull private images from ghcr.io

# Git (your repo info)
export GIT_USERNAME=
export GIT_EMAIL=
export GIT_ORIGIN_URL=
```

## Run Kargo demo

Some scripts are available to run Kargo demo:

```sh
# Create Kubernetes cluster
kind create cluster --config ./kubernetes-cluster/kind-cluster.yaml --name kargo-infrastructor
# Setup the Docker secret to pull images from private ghcr repository
# Replace Podman command if you're using Docker or other container engine
./kubernetes-cluster/setup-ghcr-registry.sh
# Install Argo CD, Kargo and their dependencies
./install-cluster.sh
# Push Helm Chart
./push-helm-chart.sh
# Run demo
./run-demo.sh
```

### Clean the demo

If you want to clean the demo, you can execute the ``clean-demo.sh`` script and ``kind delete cluster --name kargo-infrastructor`` to delete the Kubernetes cluster.

## Blog posts

Don't hesitate to read the following blog posts to find out more about Kargo:

* [Kargo, deploy from one environment to another with GitOps](https://blog.filador.ch/en/posts/kargo-deploy-from-one-environment-to-another-with-gitops/) - English version
* [Kargo, déployez d'un environnement à l'autre en mode GitOps](https://blog.filador.ch/posts/kargo-deployez-dun-environnement-a-lautre-en-mode-gitops/) - French version
