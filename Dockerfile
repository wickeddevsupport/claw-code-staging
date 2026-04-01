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

ARG CODE_SERVER_VERSION=4.112.0
ARG CONTINUE_EXTENSION=Continue.continue
ARG CLINE_EXTENSION=saoudrizwan.claude-dev

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash ca-certificates git ripgrep less procps python3 make g++ curl caddy \
  && rm -rf /var/lib/apt/lists/* \
  && npm install -g code-server@${CODE_SERVER_VERSION}

RUN useradd -m -u 10001 -s /bin/bash claw
WORKDIR /workspace

COPY --from=builder /src/repo/rust/target/release/claw /usr/local/bin/claw
COPY launch.sh /usr/local/bin/launch-claw.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/launch-claw.sh /usr/local/bin/entrypoint.sh \
  && chown -R claw:claw /workspace /home/claw \
  && runuser -u claw -- env HOME=/home/claw code-server --install-extension ${CONTINUE_EXTENSION} --force \
  && runuser -u claw -- env HOME=/home/claw code-server --install-extension ${CLINE_EXTENSION} --force

USER claw
ENV HOME=/home/claw
ENV PORT=3000
ENV CODE_SERVER_PORT=3001
EXPOSE 3000

CMD ["/usr/local/bin/entrypoint.sh"]
