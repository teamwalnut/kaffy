FROM hexpm/elixir:1.12.3-erlang-24.1.7-alpine-3.14.2 AS build

# install build dependencies
RUN apk add --no-cache libgcc build-base npm git py-pip

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV=prod

# install mix dependencies
COPY mix.exs mix.lock ./
COPY config config
RUN mix do deps.get, deps.compile

# build assets
# COPY assets/package.json assets/package-lock.json ./assets/
# RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error

COPY priv priv
# COPY assets assets
# RUN npm run --prefix ./assets deploy
# RUN mix phx.digest

ARG api_domain
ARG environment="prod"
ARG version

# compile and build release
COPY lib lib

ENV ENVIRONMENT=$environment
ENV VERSION=$version
ENV API_DOMAIN=$api_domain

# uncomment COPY if rel/ exists
# COPY rel rel
RUN mix do sentry_recompile, release

# prepare release image
FROM alpine:latest AS app
RUN apk add --no-cache openssl ncurses-libs bash libstdc++

WORKDIR /app

RUN chown nobody:nobody /app

USER nobody:nobody

COPY --from=build --chown=nobody:nobody /app/_build/prod/rel/api ./

ENV HOME=/app

CMD ["bin/api", "start"]
