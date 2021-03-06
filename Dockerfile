# syntax = docker/dockerfile:experimental
ARG BASE_IMAGE=node:14-buster-slim
ARG WORKDIR=/app
ARG USER=node

FROM ${BASE_IMAGE} as prod_deps
ARG WORKDIR
WORKDIR ${WORKDIR}
COPY package.json .
COPY yarn.lock .
RUN yarn install --frozen-lockfile --production

FROM prod_deps as deps
RUN yarn install --frozen-lockfile

FROM deps as build_base
COPY src ./src
COPY tsconfig.json .
COPY tsconfig.build.json .

FROM build_base as builder
RUN yarn build

FROM ${BASE_IMAGE} as runner
ARG USER
ARG WORKDIR
WORKDIR ${WORKDIR}
RUN chown ${USER}:${USER} ${WORKDIR}
USER ${USER}
COPY --chown=${USER}:${USER} --from=prod_deps ${WORKDIR}/node_modules ${WORKDIR}/node_modules
COPY --chown=${USER}:${USER} --from=builder ${WORKDIR}/dist ${WORKDIR}/dist
CMD ["node", "dist/main.js"]
