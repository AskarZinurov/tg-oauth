image := "tg-oauth"
current_version := shell("yq eval .version shard.yml")
registry := "askarini"
set dotenv-filename := ".env.local"

# List all recipes
list:
  @just --list

init:
  bun install
  shards

# Compile css styles
compile-css:
  bun run tailwindcss -i ./src/assets/styles.css -o ./www/styles.css --minify

# Compile app binary
compile: init
  shards build

# Build project images
build: init cleanup compile-css
	podman build -f Dockerfile -t {{image}}:latest -t {{image}}:{{current_version}} .

# Push image to remote registry
push:
	podman manifest push {{registry}}/{{image}}:{{current_version}}

# Build application image
release: build
  podman buildx build \
    --platform linux/amd64,linux/arm64 -f Dockerfile \
    --manifest {{registry}}/{{image}}:{{current_version}} .

# Cleanup built images
cleanup:
  podman image rm -f {{shell('podman images --filter=reference="$1" -q | paste -sd " " -', image)}} || true

# Run specs
spec:
  #!/usr/bin/env sh

  echo "---Starting auth specs---"
  export TELEGRAM_TOKEN="123123123:AAFBeGjdfvvSfVhZ5tqjZ5pHl9lcF888wpI"
  export TELEGRAM_BOT="oauth_bot"
  export JWT_SECRET="J,-123123123123123123123123123y2@_bR"
  export OAUTH_CLIENT_ID="zitadel"
  export OAUTH_CLIENT_SECRET="#.G(~;f>_XS~x%Mzp73L}2^8uJSV123123"
  export OAUTH_REDIRECT_URIS="http://zitadel.localhost"
  export COOKIE_SESSION_SECRET="byObbpYREv1m123pz0Xv8W6CaCmR123123"
  export APP_DOMAIN="localdomain.localhost"

  crystal spec

# Start app locally
play *FLAGS:
  podman run {{FLAGS}} \
    --name {{image}}  \
    --rm  \
    --publish 3000:3000 \
    --env TELEGRAM_TOKEN \
    --env TELEGRAM_BOT \
    --env JWT_SECRET \
    --env OAUTH_CLIENT_ID \
    --env OAUTH_CLIENT_SECRET \
    --env OAUTH_REDIRECT_URIS \
    --env COOKIE_SESSION_SECRET \
    --env APP_DOMAIN \
    {{image}}:{{current_version}}

down:
  podman stop {{image}}
