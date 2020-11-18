FROM elixir:1.10.4-alpine AS build

# install build dependencies
RUN apk add --no-cache build-base npm git curl

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

# install and build elm
# RUN git clone https://github.com/50kudos/fmodel.git
# RUN cd fmodel && \
#     npm install -g uglify-js && \
#     curl -L -o elm.gz https://github.com/elm/compiler/releases/download/0.19.1/binary-for-linux-64-bit.gz && \
#     gunzip elm.gz && \
#     chmod +x elm && \
#     mv elm /usr/local/bin/ && \
#     ./make.sh src/Main.elm && \
#     cd -

# build assets
COPY assets/package.json assets/package-lock.json ./assets/
# RUN mkdir -p ./assets/elm && \
#     cp fmodel/elm.min.js ./assets/elm/
RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error

ENV NODE_ENV=production
COPY lib lib
COPY priv priv
COPY assets assets
RUN npm run --prefix ./assets deploy
RUN mix phx.digest

# compile and build release
COPY rel rel
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

CMD bin/fset eval "Fset.Release.migrate" && bin/fset start
