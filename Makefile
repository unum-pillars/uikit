ACCOUNT=unum-pillars
IMAGE=uikit
VERSION?=$(shell cat VERSION)
PORT?=8575
TTY=$(shell if tty -s; then echo "-it"; fi)
VOLUMES=-v ${PWD}/src:/opt/service/src \
		-v ${PWD}/demo:/opt/service/demo \
		-v ${PWD}/dist:/opt/service/dist \
		-v ${PWD}/package.json:/opt/service/package.json \
		-v ${PWD}/package-lock.json:/opt/service/package-lock.json
# Packing and publishing read the source and keep nothing, so they get only what they use, read-only, and build in a copy:
# a container writing into the workspace leaves root-owned files that Jenkins can't clean up
NPM=-v ${PWD}/src:/opt/service/src:ro \
	-v ${PWD}/package.json:/opt/service/package.json:ro \
	-v ${PWD}/package-lock.json:/opt/service/package-lock.json:ro \
	-v ${PWD}/README.md:/opt/service/README.md:ro \
	-v ${PWD}/CHANGELOG.md:/opt/service/CHANGELOG.md:ro \
	-v ${PWD}/LICENSE:/opt/service/LICENSE:ro
NPMRC=-v ${HOME}/.npmrc:/root/.npmrc

.PHONY: stop build shell css dist demo pack publish clean tag untag new version release-check release test-release help
.DEFAULT_GOAL := help

build: ## Builds the docker image
	docker build . -t $(ACCOUNT)/$(IMAGE):$(VERSION)

shell: ## Opens a shell in the container
	docker run $(TTY) $(VOLUMES) $(ACCOUNT)/$(IMAGE):$(VERSION) sh

css: ## Compiles the theme to dist/css
	mkdir -p dist
	docker run $(TTY) $(VOLUMES) $(ACCOUNT)/$(IMAGE):$(VERSION) npm run css

dist: ## Compiles dist/css and copies dist/js
	mkdir -p dist
	docker run $(TTY) $(VOLUMES) $(ACCOUNT)/$(IMAGE):$(VERSION) npm run build

demo: ## Serves the kitchen-sink page on PORT (default 8575)
	-@docker rm -f uikit-demo >/dev/null 2>&1
	mkdir -p dist
	docker run --rm --init --name uikit-demo $(TTY) $(VOLUMES) -e PUBLIC_PORT=$(PORT) -p 127.0.0.1:$(PORT):8080 $(ACCOUNT)/$(IMAGE):$(VERSION) npm run demo

pack: ## Builds and previews the npm tarball
	docker run --rm $(TTY) $(NPM) $(ACCOUNT)/$(IMAGE):$(VERSION) sh -c "cp -r /opt/service /opt/install && cd /opt/install && npm run build && npm pack --dry-run"

publish: ## Publishes the version to npm with your ~/.npmrc
	@test -f ${HOME}/.npmrc || (echo "no ${HOME}/.npmrc to publish with" && exit 1)
	docker run --rm $(TTY) $(NPM) $(NPMRC) $(ACCOUNT)/$(IMAGE):$(VERSION) sh -c "cp -r /opt/service /opt/install && cd /opt/install && npm run build && npm publish --access public"

stop: ## Stops the demo
	-docker rm -f uikit-demo

clean: ## Removes dist
	rm -rf dist

tag: ## Tags the version and pushes the tag
	git rev-parse -q --verify refs/tags/$(VERSION) || git tag -a $(VERSION) -m "Version $(VERSION)"
	git push origin --tags

untag: ## Removes the version's tag
	-git tag -d $(VERSION)
	git push origin ":refs/tags/$(VERSION)"

# Releases: make new starts one, make release-check says where it's up to and what would stop it, make release finishes it.
# V is +0.0.1 (the default), +0.1, +1 or a version outright, and B names the branch. The work is in scripts/.
V?=+0.0.1
B?=

new: ## Starts a release: next version, branch, VERSION, package.json, changelog (V=+0.0.1|+0.1|+1|x.y.z, B=name)
	@sh scripts/new.sh "$(V)" "$(B)"

version: ## Sets VERSION and package.json to match (V=+0.0.1|+0.1|+1|x.y.z)
	@sh scripts/version.sh write "$(V)"

release-check: ## Says where the release is up to and what would stop it
	@sh scripts/release-check.sh

release: ## Does what's left of the release: checks, npm, the tag
	@sh scripts/release.sh

# Tests the release scripts against a throwaway repo and a fake registry, nothing real is touched
test-release: ## Tests the release scripts against a throwaway repo and a fake registry
	docker run --rm $(TTY) -v ${PWD}/scripts:/opt/scripts python:3 sh /opt/scripts/test-release.sh

help: ## Lists the targets
	@awk -F ':.*## ' '/^[a-z-]+:.*## /{printf "%-16s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
