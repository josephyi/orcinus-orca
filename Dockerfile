# syntax = docker/dockerfile:experimental
ARG BASE_IMAGE=node:14.3-alpine
FROM ${BASE_IMAGE} as prod_deps
WORKDIR /app
COPY package.json .
COPY yarn.lock .
RUN --mount=type=cache,target=/app/.cache/yarn \
    --mount=type=cache,target=/app/node_modules \
    yarn install --frozen-lockfile --production --cache-folder .cache

FROM prod_deps as deps
RUN --mount=type=cache,target=/app/.cache/yarn \
    --mount=type=cache,target=/app/node_modules \
    yarn install --frozen-lockfile --cache-folder .cache

FROM deps as builder
COPY src .
COPY tsconfig.json .
COPY tsconfig.build.json .
RUN yarn build

FROM builder as runner
USER node
COPY --chown=node:node --from=prod_deps node_modules ./node_modules
COPY --chown=node:node --from=builder dist ./dist
CMD ["node", "dist/main.js"]
