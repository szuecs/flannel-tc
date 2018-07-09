BINARY      ?= flannel-tc
VERSION     ?= $(shell git describe --tags --always --dirty)
IMAGE       ?= registry-write.opensource.zalan.do/teapot/$(BINARY)
TAG         ?= $(VERSION)
DOCKERFILE  ?= Dockerfile

default: docker.build

docker.build:
	docker build --rm -t "$(IMAGE):$(TAG)" .

docker.push: docker.build
	docker push "$(IMAGE):$(TAG)"

build.release.image: build.package
	docker build --rm -t "$(IMAGE)-release:$(RELEASE_TAG)" -f $(DOCKERFILE).release .

build.release.image.push: build.release.image
	docker push "$(IMAGE)-release:$(RELEASE_TAG)"
