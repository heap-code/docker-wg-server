IMAGE ?= wg-server:dev

SH_FILES := wg-server.sh $(wildcard scripts/*.sh)
BATS_FILES := $(wildcard tests/*/*.bats)

# Pinned linters, run through docker so local, devcontainer and CI behave the same
DOCKER_RUN_MNT := docker run --rm -v "$(CURDIR):/mnt" -w /mnt
SHELLCHECK ?= $(DOCKER_RUN_MNT) koalaman/shellcheck:v0.10.0
SHFMT ?= $(DOCKER_RUN_MNT) mvdan/shfmt:v3.10.0

.PHONY: all lint fmt build build-test test test-unit test-integration

all: lint test

lint:
	$(SHELLCHECK) $(SH_FILES) $(BATS_FILES)
	$(SHFMT) -d $(SH_FILES) $(BATS_FILES)

fmt:
	$(SHFMT) -w $(SH_FILES) $(BATS_FILES)

build:
	docker build -t $(IMAGE) .

build-test:
	docker build --target test -t $(IMAGE)-test .

test: test-unit test-integration

# No privileges needed: file/keygen logic only
test-unit: build-test
	docker run --rm $(IMAGE)-test

# Needs a host kernel with WireGuard and permission to run NET_ADMIN containers
test-integration: build
	IMAGE=$(IMAGE) bats --print-output-on-failure tests/integration
