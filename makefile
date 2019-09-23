IMAGE := ministryofjustice/cloud-platform-tools
TAG := 1.1

build:
	docker build -t $(IMAGE) .

tag:
	docker tag $(IMAGE) $(IMAGE):$(TAG)

push:
	docker tag $(IMAGE) $(IMAGE):$(TAG)
	docker push $(IMAGE):$(TAG)
