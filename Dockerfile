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
  echo $LEAN_VERSION > LEAN_VERSION.txt && \
  curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh -s -- -y --no-modify-path --default-toolchain $LEAN_VERSION; \
    chmod -R a+w $ELAN_HOME; \
    elan --version; \
    lean --version; \
    leanc --version; \
    lake --version;

USER node

# pnpm just doesn't work
RUN cd nng4 && lake update -R && lake exe cache get && lake build && lake clean && \
  cd ~/lean4game && npm i --production && \
  cd ~/lean4game && npm run build && \
  npm cache clean --force && rm -rf ./.cache \
  cd ~/nng4 && lake clean

EXPOSE 3000
CMD ["sh", "-c", "cd lean4game && (npm run start_server & npm run start_client)"]