FROM hexpm/elixir:1.17.3-erlang-27.3.4-alpine-3.21.3 AS builder-deps

WORKDIR /app

RUN apk --no-cache --update add \
    alpine-sdk gmp-dev automake libtool inotify-tools autoconf python3 file gcompat libstdc++ curl ca-certificates git make bash

# Clone the Blockscout repository
RUN git clone --depth 1 https://github.com/blockscout/blockscout.git /app/blockscout

WORKDIR /app/blockscout

ENV MIX_ENV="prod"
ENV MIX_HOME=/opt/mix
ARG CHAIN_TYPE=ethereum
ENV CHAIN_TYPE=$CHAIN_TYPE
RUN mix local.hex --force
RUN mix do deps.get, local.rebar --force, deps.compile --skip-umbrella-children

##############################################################
FROM builder-deps AS builder

ENV ADMIN_PANEL_ENABLED=false
ENV DISABLE_WEBAPP=true
ENV DISABLE_API=false
ENV DISABLE_INDEXER=false

WORKDIR /app/blockscout

# Run backend compilation
RUN mix compile

RUN mkdir -p /opt/release && \
    mix release blockscout && \
    mv _build/${MIX_ENV}/rel/blockscout /opt/release
# Copy config_helper.exs and any other required files to the release directory
RUN cp /app/blockscout/config/config_helper.exs /opt/release/blockscout/config_helper.exs && \
    cp /app/blockscout/config/config_helper.exs /opt/release/blockscout/releases/$(cat /opt/release/blockscout/releases/start_erl.data | cut -d' ' -f2)/config_helper.exs


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

ENV DISABLE_WEBAPP=true
ENV DISABLE_API=false
ENV DISABLE_INDEXER=false
ENV DISABLE_MARKET=true
ENV ADMIN_PANEL_ENABLED=false
ENV ACCOUNT_ENABLED=false
ENV CHAIN_ID=1
ENV CHAIN_TYPE=ethereum
ENV NETWORK=ethereum
ENV COIN=ETH
ENV ECTO_USE_SSL=false


ENV API_GRAPHQL_ENABLED=false
ENV API_V2_ENABLED=true
ENV API_V1_READ_METHODS_DISABLED=false
ENV API_V1_WRITE_METHODS_DISABLED=false

ENV MICROSERVICE_VISUALIZE_SOL2UML_ENABLED=false
ENV MICROSERVICE_ACCOUNT_ABSTRACTION_ENABLED=true
ENV MICROSERVICE_SIG_PROVIDER_ENABLED=true
ENV MICROSERVICE_SC_VERIFIER_ENABLED=true
ENV MICROSERVICE_SC_VERIFIER_TYPE=eth_bytecode_db
ENV MICROSERVICE_ACCOUNT_ABSTRACTION_URL=http://user-ops-indexer:8050/
ENV MICROSERVICE_SIG_PROVIDER_URL=http://sig-provider:8050/
ENV MICROSERVICE_SC_VERIFIER_URL=http://smart-contract-verifier:8050/
ENV TXS_STATS_DAYS_TO_COMPILE_AT_INIT=0
ENV COIN_BALANCE_HISTORY_DAYS=0
ENV RE_CAPTCHA_DISABLED=false
ENV DECODE_NOT_A_CONTRACT_CALLS=true
ENV NFT_MEDIA_HANDLER_ENABLED=false
ENV PORT=4000
ENV FIRST_BLOCK=1

COPY --from=builder --chown=appuser /opt/release/blockscout .
COPY --from=builder /app/blockscout/config/config_helper.exs ./config/config_helper.exs

RUN mkdir dets && mkdir temp && chown -R appuser /app

USER appuser
EXPOSE 4000
ENTRYPOINT ["sh", "-c"]
CMD ["bin/blockscout eval \"Elixir.Explorer.ReleaseTasks.create_and_migrate()\" && bin/blockscout start"]