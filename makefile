IMAGE := ministryofjustice/cloud-platform-tools
TAG := 1.6

# This image is built and pushed via a concourse pipeline:
#
# https://concourse.cloud-platform.service.justice.gov.uk/teams/main/pipelines/tools-image/jobs/build-cp
#
# So, it should not normally be necessary to use the build process defined here.
#

build: .built-docker-image

.built-docker-image: Dockerfile makefile
	docker build -t $(IMAGE) .
	touch .built-docker-image

tag:
	docker tag $(IMAGE) $(IMAGE):$(TAG)

push: .built-docker-image
	docker tag $(IMAGE) $(IMAGE):$(TAG)
	docker push $(IMAGE):$(TAG)
