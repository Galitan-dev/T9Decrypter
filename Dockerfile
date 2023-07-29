FROM alpine:latest
LABEL author="Galitan-dev"

RUN apk add --no-cache nasm gcc make

WORKDIR /run

ADD src /run/src
ADD assets /run/assets
ADD Makefile /run/Makefile

RUN make build

CMD [ "/run/dist/main" ]
