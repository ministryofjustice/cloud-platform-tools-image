# This image is built and pushed via a github action
#
# See .github/workflows/docker-hub.yml
#

shell:
	docker run --rm -it \
		-v $$(pwd):/app \
		-v $${HOME}/.kube:/app/.kube \
		-e KUBECONFIG=/app/.kube/config \
		-v $${HOME}/.aws:/root/.aws \
		-v $${HOME}/.gnupg:/root/.gnupg \
		-w /app ministryofjustice/cloud-platform-tools bash
