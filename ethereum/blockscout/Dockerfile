FROM hexpm/elixir:1.17.3-erlang-27.3.4-alpine-3.21.3 AS builder-deps

WORKDIR /app

RUN apk --no-cache --update add \
    alpine-sdk gmp-dev automake libtool inotify-tools autoconf python3 file gcompat libstdc++ curl ca-certificates git make bash

# Cache elixir deps
COPY mix.exs mix.lock ./
COPY apps/explorer/mix.exs ./apps/explorer/
COPY apps/ethereum_jsonrpc/mix.exs ./apps/ethereum_jsonrpc/
COPY apps/indexer/mix.exs ./apps/indexer/
COPY apps/utils/mix.exs ./apps/utils/

ENV MIX_ENV="prod"
ENV MIX_HOME=/opt/mix
RUN mix local.hex --force
RUN mix do deps.get, local.rebar --force, deps.compile --skip-umbrella-children

COPY config ./config
COPY rel ./rel
COPY apps ./apps

##############################################################
FROM builder-deps AS builder

ENV ADMIN_PANEL_ENABLED=false
ENV DISABLE_WEBAPP=true
ENV DISABLE_API=false
ENV DISABLE_INDEXER=false

# Run backend compilation
RUN mix compile

RUN mkdir -p /opt/release && \
    mix release blockscout && \
    mv _build/${MIX_ENV}/rel/blockscout /opt/release

##############################################################
FROM hexpm/elixir:1.17.3-erlang-27.3.4-alpine-3.21.3

WORKDIR /app

ARG UID=10001
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    appuser

ENV ADMIN_PANEL_ENABLED=false
ENV DISABLE_WEBAPP=true
ENV DISABLE_API=false
ENV DISABLE_INDEXER=false

COPY --from=builder --chown=appuser /opt/release/blockscout .
COPY --from=builder --chown=appuser /app/config/config_helper.exs ./config/config_helper.exs
COPY --from=builder --chown=appuser /app/config/assets/precompiles-arbitrum.json ./config/assets/precompiles-arbitrum.json

RUN mkdir dets && mkdir temp && chown -R appuser /app

USER appuser