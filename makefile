IMAGE := ministryofjustice/cloud-platform-tools
# This image is built and pushed via a github action
TAG := 1.20# This image is built and pushed via a github action
#
# See .github/workflows/docker-hub.yml
#
build: .built-docker-image

.built-docker-image: Dockerfile makefile
	docker build -t $(IMAGE) .
	touch .built-docker-image

tag:
	docker tag $(IMAGE) $(IMAGE):$(TAG)

push: .built-docker-image
	make tag
	docker push $(IMAGE):$(TAG)

shell:
	docker run --rm -it \
		-v $$(pwd):/app \
		-v $${HOME}/.kube:/app/.kube \
		-e KUBECONFIG=/app/.kube/config \
		-v $${HOME}/.aws:/root/.aws \
		-v $${HOME}/.gnupg:/root/.gnupg \
		-w /app ministryofjustice/cloud-platform-tools bash
