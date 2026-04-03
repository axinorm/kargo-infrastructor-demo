#!/bin/sh
set -o errexit

# Desired cluster name; default is "kind"
KIND_CLUSTER_NAME="${KIND_CLUSTER_NAME:-kind}"

# GHCR credentials - It is recommended to set these as environment variables
# IMAGE_REGISTRY_GITHUB_PAT: A GitHub Personal Access Token (PAT) with 'read:packages' scope
IMAGE_REGISTRY_GITHUB_PAT="${IMAGE_REGISTRY_GITHUB_PAT:-}"

if [ -z "$IMAGE_REGISTRY_GITHUB_PAT" ]; then
  echo "Error: IMAGE_REGISTRY_GITHUB_PAT environment variable must be set."
  echo "Example: export IMAGE_REGISTRY_GITHUB_PAT='your-token'"
  exit 1
fi

# Create a temp file for the podman config
echo "Creating temporary podman client config directory ..."
DOCKER_CONFIG=$(mktemp -d)
export DOCKER_CONFIG
trap 'echo "Removing ${DOCKER_CONFIG}/*" && rm -rf ${DOCKER_CONFIG:?}' EXIT

echo "Creating a temporary config.json"
# Force the omission of credsStore to ensure credentials land in config.json
cat <<EOF >"${DOCKER_CONFIG}/config.json"
{
 "auths": { "ghcr.io": {} }
}
EOF

# Login to ghcr.io in DOCKER_CONFIG
echo "Logging in to GHCR in temporary podman client config directory ..."
echo "${IMAGE_REGISTRY_GITHUB_PAT}" | podman login ghcr.io -u x-access-token --password-stdin

# Setup credentials on each node
echo "Moving credentials to kind cluster name='${KIND_CLUSTER_NAME}' nodes ..."
for node in $(kind get nodes --name "${KIND_CLUSTER_NAME}"); do
  # The -oname format is kind/name (so node/name) we just want name
  node_name=${node#node/}
  # Copy the config to where kubelet will look
  podman cp "${DOCKER_CONFIG}/config.json" "${node_name}:/var/lib/kubelet/config.json"
  # Restart kubelet to pick up the config
  podman exec "${node_name}" systemctl restart kubelet.service
done

echo "Done!"
