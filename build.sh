#!/usr/bin/env bash

# This script uses arg $1 (name of *.jsonnet file to use) to generate the deploy/*.yaml files.

set -e
set -x
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

# Make sure to use project tooling
PATH="$(pwd)/tmp/bin:${PATH}"

# Make sure to start with a clean 'deploy' dir
rm -rf deploy
mkdir -p deploy/setup

# Calling gojsontoyaml is optional, but we would like to generate yaml, not json
jsonnet -J vendor -m deploy "${1-monitoring.jsonnet}" | xargs -I{} sh -c 'cat {} | gojsontoyaml > {}.yaml' -- {}

# Make sure to remove json files
find deploy -type f ! -name '*.yaml' -delete

# Generate deploy/kustomization.yml
pushd deploy
cat <<EOF > kustomization.yml
resources:
- ./setup
$(for f in ./*.yaml ; do echo - $f ; done)
EOF

# Generate deploy/setup/kustomization.yml
pushd setup
cat <<EOF > kustomization.yml
commonAnnotations:
  argocd.argoproj.io/sync-options: Replace=true
resources:
$(for f in ./*.yaml ; do echo - $f ; done)
EOF

popd
popd
