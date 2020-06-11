# MoJ Cloud Platform 'tools' image

A docker image with a set of useful software tools installed, for managing the cloud platform.

The image includes:

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
  - `setup-kube-auth`
  - `tag-and-push-docker-image`

## Building and tagging the tools image

A github action builds the tools image and pushes it to [DockerHub](https://hub.docker.com/r/ministryofjustice/cloud-platform-tools) whenever a new release is defined in github.

The image is tagged with the release number.

## setup-kube-auth

This is a bash script that automates the process of authenticating to the cloud platform, for use in automated build pipelines.

For each "environment" (kuberenetes context) that's required in your build pipeline, the script expects to find the following environment variables:

- `KUBE_ENV_XYZ_NAME`, the name of the cluster (which also determines its host)
- `KUBE_ENV_XYZ_NAMESPACE`, the namespace to target in that cluster
- `KUBE_ENV_XYZ_CACERT` and`KUBE_ENV_XYZ_TOKEN`, from [ServiceAccount][how-to-serviceaccount]

It will configure `kubectl` with a context named `xyz`.

## tag-and-push-docker-image

This is a script to simplify the process of pushing a service team's docker image to DockerHub, and tagging it with the SHA1 of the latest commit.

[how-to-serviceaccount]: https://user-guide.cloud-platform.service.justice.gov.uk/documentation/deploying-an-app/using-circleci-for-continuous-deployment.html#creating-a-service-account-for-circleci
