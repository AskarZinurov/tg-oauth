# Tg OAUTH

This is OAuth implementation for Telegram [login widget](https://core.telegram.org/widgets/login).

So now you can use Telegram as external provider for your SSO server (keycloak, etc.).

## Testing

`just spec`

## Compiling

First you need to install dev tools:

* [crystal](https://crystal-lang.org/install/)
* [just](https://just.systems/man/en/packages.html)
* [bun](https://bun.sh/docs/installation)
* [podman](https://podman.io/docs/installation) or [docker](https://docs.docker.com/get-started/get-docker/)

Then you can run `just build`

### Running locally

```
podman run \
    --name tg-oauth \
    --rm \
    --publish 3000:3000 \
    --env TELEGRAM_TOKEN \
    --env TELEGRAM_BOT \
    --env JWT_SECRET \
    --env OAUTH_CLIENT_ID \
    --env OAUTH_CLIENT_SECRET \
    --env OAUTH_REDIRECT_URIS \
    --env COOKIE_SESSION_SECRET \
    --env APP_DOMAIN \
    askarini/tg-oauth:0.1.15
```
