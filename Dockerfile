FROM registry.opensource.zalan.do/stups/ubuntu:latest
MAINTAINER Team Teapot @ Zalando SE <team-teapot@zalando.de>

RUN apt-get update; \
	apt-get install -y iproute2 coreutils procps iptables

# add script
ADD tc-flannel.sh /

