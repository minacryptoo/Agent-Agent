.PHONY: install dev build test deploy clean setup

install:
	pnpm install

dev:
	turbo run dev

build:
	turbo run build

test:
	turbo run test

deploy:
	cd packages/contracts && forge script Deploy --broadcast --rpc-url $$BASE_RPC_URL

setup:
	./scripts/setup/init-project.sh

clean:
	rm -rf node_modules packages/*/node_modules packages/*/dist packages/*/build
