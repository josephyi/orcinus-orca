ARG BASE_IMAGE=node:14.3-alpine
FROM ${BASE_IMAGE} as prod_deps
COPY package.json .
COPY yarn.lock .
RUN yarn install --frozen-lockfile --production

FROM prod_deps as deps
RUN yarn install --frozen-lockfile

FROM deps as builder
COPY src .
COPY tsconfig.json .
COPY tsconfig.build.json .
RUN yarn build

FROM builder as runner
COPY --from=prod_deps node_modules ./node_modules
COPY --from=builder dist ./dist
CMD ["node", "dist/main.js"]
