# syntax = docker/dockerfile:experimental
ARG BASE_IMAGE=node:14.3-alpine
ARG WORKDIR=/app
ARG USER=node

FROM ${BASE_IMAGE} as prod_deps
ARG WORKDIR
WORKDIR ${WORKDIR}
COPY package.json .
COPY yarn.lock .
COPY tsconfig.json .
COPY tsconfig.build.json .
RUN yarn install --frozen-lockfile --production

FROM prod_deps as deps
ARG WORKDIR
RUN yarn install --frozen-lockfile

FROM deps as builder
COPY src ./src
RUN yarn build

FROM builder as runner
ARG USER
ARG WORKDIR
WORKDIR ${WORKDIR}
RUN chown ${USER}:${USER} ${WORKDIR}
USER ${USER}
COPY --chown=${USER}:${USER} --from=prod_deps ${WORKDIR}/node_modules ${WORKDIR}/node_modules
COPY --chown=${USER}:${USER} --from=builder ${WORKDIR}/dist ${WORKDIR}/dist
CMD ["node", "dist/main.js"]
