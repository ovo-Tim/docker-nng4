FROM node:20 AS builder

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

USER node

WORKDIR /home/node

RUN git clone --depth 1 https://github.com/leanprover-community/NNG4.git nng4

RUN export LEAN_VERSION="$(cat nng4/lean-toolchain | grep -oE '[^:]+$')" && git clone --depth 1 --branch $LEAN_VERSION https://github.com/leanprover-community/lean4game.git

ENV ELAN_HOME=/usr/local/elan \
  PATH=/usr/local/elan/bin:$PATH

USER root

RUN export LEAN_VERSION="$(cat nng4/lean-toolchain)" && \
  curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh -s -- -y --no-modify-path --default-toolchain $LEAN_VERSION; \
    chmod -R a+w $ELAN_HOME; \
    elan --version; \
    lean --version; \
    leanc --version; \
    lake --version;

USER node

RUN cd nng4 && lake update -R && lake exe cache get && lake build
# pnpm just doesn't work
# --production seems not working
RUN cd lean4game && npm i
RUN cd lean4game && npm run build && npx node-prune



FROM node:20-alpine

USER root
RUN npm install -g concurrently && npm cache clean --force

USER node
WORKDIR /home/node

COPY --from=builder /home/node/lean4game /home/node/lean4game
COPY --from=builder /home/node/nng4 /home/node/nng4

EXPOSE 3000
CMD cd ~/lean4game && npm start