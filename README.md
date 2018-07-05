# cloud-platform-tools-image

The repository produces two images:

- the main image includes:
  - `aws`
  - `helm`
  - `kops`
  - `kubectl`
  - `terraform`
- the CircleCI build image includes:
  - `aws`
  - `helm`
  - `kubectl`

Docker images are versioned by commit SHA and are available at `926803513772.dkr.ecr.eu-west-1.amazonaws.com/cloud-platform/tools`.

CircleCI image tags used the `-circleci` suffix, eg.: `926803513772.dkr.ecr.eu-west-1.amazonaws.com/cloud-platform/tools:latest-circleci`.

## CircleCI

The CircleCI image is based on the upstream `docker` image and includes `setup-kube-auth` (also set as the entrypoint) which aims to simplify using `kubectl` on CircleCI.

For each "environment" (kuberenetes context) that's required in CircleCI, it expects to find the following environment variables:
- `KUBE_ENV_XYZ_NAME`, the name of the cluster (which also determines its host)
- `KUBE_ENV_XYZ_NAMESPACE`, the namespace to target in that cluster
- `KUBE_ENV_XYZ_CACERT` and`KUBE_ENV_XYZ_TOKEN`, from ServiceAccount

It will configure `kubectl` with a context named `xyz`.
