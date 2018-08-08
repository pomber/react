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
COPY --from=0 /repo/fixtures/unstable-async/suspense /repo/fixtures/unstable-async/suspense

WORKDIR /repo

RUN yarn --cwd fixtures/unstable-async/suspense

ENV FORKBOX_BRANCH_NAME ${BRANCH_NAME}
ENV FORKBOX_REPO_URL ${REPO_URL}

CMD git remote set-url origin $FORKBOX_REPO_URL && \
    git config remote.origin.fetch +refs/heads/$FORKBOX_BRANCH_NAME:refs/remotes/origin/$FORKBOX_BRANCH_NAME && \
    git fetch origin $FORKBOX_BRANCH_NAME && \
    git checkout $FORKBOX_BRANCH_NAME && \
    (watch -n 3 git pull &>/dev/null &) && \
    cd fixtures/unstable-async/suspense && \
    yarn start
