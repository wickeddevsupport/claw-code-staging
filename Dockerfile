FROM rust:1.88-bookworm AS builder

ARG CLAW_CODE_REF=9ade3a70d70ae690ae15d3c8f1de7e6d03d87a2a

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates git pkg-config libssl-dev \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone https://github.com/instructkr/claw-code.git repo \
  && cd repo \
  && git checkout "$CLAW_CODE_REF"

WORKDIR /src/repo/rust
RUN cargo build --release -p rusty-claude-cli

FROM node:22-bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash ca-certificates git ripgrep less procps python3 make g++ \
  && rm -rf /var/lib/apt/lists/* \
  && npm install -g wetty

RUN useradd -m -u 10001 -s /bin/bash claw
WORKDIR /workspace

COPY --from=builder /src/repo/rust/target/release/claw /usr/local/bin/claw
COPY launch.sh /usr/local/bin/launch-claw.sh
RUN chmod +x /usr/local/bin/launch-claw.sh && chown -R claw:claw /workspace

USER claw
ENV HOME=/home/claw
ENV PORT=3000
EXPOSE 3000

CMD ["/bin/bash", "-lc", "exec wetty --host 0.0.0.0 --port ${PORT:-3000} --base / --command /usr/local/bin/launch-claw.sh"]
