# This file is a temporary measure whilst moving the tools image from
# an AWS ECR to Docker Hub.
#
# Ultimately, this should be done by concourse, and this makefile can
# be removed.

build: .built-image

push:
	docker tag cloud-platform-tools ministryofjustice/cloud-platform-tools
	docker push ministryofjustice/cloud-platform-tools

.built-image: Dockerfile
	docker build -t cloud-platform-tools .
	make push
	touch .built-image
