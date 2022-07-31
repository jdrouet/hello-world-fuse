FROM --platform=$BUILDPLATFORM rust:slim-bullseye AS fetcher

WORKDIR /code
RUN cargo init

WORKDIR /code
COPY Cargo.lock Cargo.toml /code/

RUN mkdir -p /code/.cargo \
  && cargo vendor > /code/.cargo/config

FROM rust:slim-bullseye AS builder

RUN apt-get update && apt-get install -y gcc libfuse-dev pkg-config

ENV USER=root

COPY --from=fetcher /code /code

WORKDIR /code

COPY src/main.rs /code/src/main.rs

RUN --mount=type=cache,sharing=locked,target=/code/target/release/deps \
  --mount=type=cache,sharing=locked,target=/code/target/release/build \
  --mount=type=cache,sharing=locked,target=/code/target/release/examples \
  --mount=type=cache,sharing=locked,target=/code/target/release/incremental \
  cargo build --offline --release

FROM --platform=$BUILDPLATFORM scratch AS artifact

COPY --from=builder /code/target/release/hello-world-fuse /
