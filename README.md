# cloud-platform-tools-image

The repository produces two images:

- the main image includes:
  - `aws`
  - `git-crypt`
  - `helm`
  - `kops`
  - `kubectl`
  - `openssh-keygen`
  - `postgresql-client`
  - `ruby`
  - `terraform`
  - `aws-iam-authenticator`
- the CircleCI build image includes:
  - `aws`
  - `helm`
  - `kubectl`

## Tagging

Docker images are tagged using the git commit SHA and are available at [DockerHub](https://hub.docker.com/r/ministryofjustice/cloud-platform-tools)

For the base image, the latest version is also tagged as `latest`.
For the CircleCI images, the git commit SHA is suffixed with `-circleci`, the latest version is tagged as `circleci`.

## CircleCI

The CircleCI image is based on the upstream `docker` image and includes `setup-kube-auth` (also set as the entrypoint) which aims to simplify using `kubectl` on CircleCI.

For each "environment" (kuberenetes context) that's required in CircleCI, it expects to find the following environment variables:

- `KUBE_ENV_XYZ_NAME`, the name of the cluster (which also determines its host)
- `KUBE_ENV_XYZ_NAMESPACE`, the namespace to target in that cluster
- `KUBE_ENV_XYZ_CACERT` and`KUBE_ENV_XYZ_TOKEN`, from [ServiceAccount][how-to-serviceaccount]

It will configure `kubectl` with a context named `xyz`.

[how-to-serviceaccount]: https://user-guide.cloud-platform.service.justice.gov.uk/tasks.html#creating-a-service-account-for-circleci
