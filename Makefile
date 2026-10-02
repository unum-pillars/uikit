ACCOUNT=unum-pillars
IMAGE=uikit
VERSION?=$(shell cat VERSION)
PORT?=8080
TTY=$(shell if tty -s; then echo "-it"; fi)
VOLUMES=-v ${PWD}/src:/opt/service/src \
		-v ${PWD}/demo:/opt/service/demo \
		-v ${PWD}/dist:/opt/service/dist \
		-v ${PWD}/package.json:/opt/service/package.json \
		-v ${PWD}/package-lock.json:/opt/service/package-lock.json
NPM=-v ${PWD}/README.md:/opt/service/README.md \
	-v ${PWD}/CHANGELOG.md:/opt/service/CHANGELOG.md \
	-v ${PWD}/LICENSE:/opt/service/LICENSE
NPMRC=-v ${HOME}/.npmrc:/root/.npmrc

.PHONY: stop build shell css dist demo pack publish clean tag untag

build:
	docker build . -t $(ACCOUNT)/$(IMAGE):$(VERSION)

shell:
	docker run $(TTY) $(VOLUMES) $(ACCOUNT)/$(IMAGE):$(VERSION) sh

css:
	mkdir -p dist
	docker run $(TTY) $(VOLUMES) $(ACCOUNT)/$(IMAGE):$(VERSION) npm run css

dist:
	mkdir -p dist
	docker run $(TTY) $(VOLUMES) $(ACCOUNT)/$(IMAGE):$(VERSION) npm run build

demo:
	mkdir -p dist
	-@docker rm -f uikit-demo >/dev/null 2>&1
	docker run --rm --name uikit-demo $(TTY) $(VOLUMES) -p 127.0.0.1:$(PORT):8080 $(ACCOUNT)/$(IMAGE):$(VERSION) npm run demo

pack:
	mkdir -p dist
	docker run $(TTY) $(VOLUMES) $(NPM) $(ACCOUNT)/$(IMAGE):$(VERSION) sh -c "npm run build && npm pack --dry-run"

publish:
	@test -f ${HOME}/.npmrc || (echo "no ${HOME}/.npmrc to publish with" && exit 1)
	mkdir -p dist
	docker run $(TTY) $(VOLUMES) $(NPM) $(NPMRC) $(ACCOUNT)/$(IMAGE):$(VERSION) sh -c "npm run build && npm publish --access public"

stop:
	-docker rm -f uikit-demo

clean:
	rm -rf dist

tag:
	-git tag -a $(VERSION) -m "Version $(VERSION)"
	git push origin --tags

untag:
	-git tag -d $(VERSION)
	git push origin ":refs/tags/$(VERSION)"
