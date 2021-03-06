FROM anapsix/alpine-java:latest

WORKDIR /repo

ARG BRANCH_NAME=master
ARG REPO_URL=https://github.com/forkboxlabs/react

RUN apk add --update git nodejs yarn 
RUN git clone --depth 1 -b ${BRANCH_NAME} --single-branch ${REPO_URL} .
RUN yarn 
RUN yarn build dom,core,interaction,simple-cache-provider --type=NODE 

FROM node:8-alpine

RUN apk add --update wget git && \
	mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2 && \
	rm -rf /var/cache/apk/*

COPY --from=0 /repo/.git /repo/.git
COPY --from=0 /repo/build/node_modules /repo/build/node_modules
COPY --from=0 /repo/fixtures/unstable-async/time-slicing /repo/fixtures/unstable-async/time-slicing

WORKDIR /repo

RUN yarn --cwd fixtures/unstable-async/time-slicing

CMD (watch -n 3 git pull &>/dev/null &) && cd fixtures/unstable-async/time-slicing/ && yarn start
