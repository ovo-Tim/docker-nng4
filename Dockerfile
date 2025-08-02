FROM node:20

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
RUN cd lean4game && npm i --production
RUN cd lean4game && npm run build
RUN npm cache clean --force

EXPOSE 3000
CMD cd ~/lean4game && npm run start_client