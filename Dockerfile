FROM elixir:1.10.4-alpine AS build

# install build dependencies
RUN apk add --no-cache build-base npm git python

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
COPY assets/package.json assets/package-lock.json ./assets/
RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error

ENV NODE_ENV=production
COPY lib lib
COPY priv priv
COPY assets assets
RUN npm run --prefix ./assets deploy
RUN mix phx.digest

# compile and build release
RUN mix do compile, release

# prepare release image
FROM alpine:3.9 AS app
RUN apk add --no-cache openssl ncurses-libs

WORKDIR /app

# RUN chown nobody:nobody /app

# USER nobody:nobody

# COPY --from=build --chown=nobody:nobody /app/_build/prod/rel/fset ./
COPY --from=build /app/_build/prod/rel/fset ./

ENV HOME=/app
ENV PORT=8080

CMD ["bin/fset", "start"]
