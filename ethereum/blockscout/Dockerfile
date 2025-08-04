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

ARG BLOCKSCOUT_USER=blockscout
ARG BLOCKSCOUT_GROUP=blockscout
ARG BLOCKSCOUT_UID=10001
ARG BLOCKSCOUT_GID=10001

RUN apk --no-cache --update add jq curl && \
    addgroup --system --gid ${BLOCKSCOUT_GID} ${BLOCKSCOUT_GROUP} && \
    adduser --system --uid ${BLOCKSCOUT_UID} --ingroup ${BLOCKSCOUT_GROUP} --disabled-password --home /app ${BLOCKSCOUT_USER}

ENV ADMIN_PANEL_ENABLED=false
ENV DISABLE_WEBAPP=true
ENV DISABLE_API=false
ENV DISABLE_INDEXER=false

ARG RELEASE_VERSION
ENV RELEASE_VERSION=${RELEASE_VERSION}
ARG BLOCKSCOUT_VERSION
ENV BLOCKSCOUT_VERSION=${BLOCKSCOUT_VERSION}

COPY --from=builder --chown=${BLOCKSCOUT_USER}:${BLOCKSCOUT_GROUP} /opt/release/blockscout .
COPY --from=builder --chown=${BLOCKSCOUT_USER}:${BLOCKSCOUT_GROUP} /app/config/config_helper.exs ./config/config_helper.exs
COPY --from=builder --chown=${BLOCKSCOUT_USER}:${BLOCKSCOUT_GROUP} /app/config/config_helper.exs /app/releases/${RELEASE_VERSION}/config_helper.exs
COPY --from=builder --chown=${BLOCKSCOUT_USER}:${BLOCKSCOUT_GROUP} /app/config/assets/precompiles-arbitrum.json ./config/assets/precompiles-arbitrum.json

RUN mkdir dets && mkdir temp && chown -R ${BLOCKSCOUT_USER}:${BLOCKSCOUT_GROUP} /app

USER ${BLOCKSCOUT_USER}:${BLOCKSCOUT_GROUP}
