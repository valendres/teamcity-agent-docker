FROM ubuntu:14.04

ENV AGENT_DIR  /opt/buildAgent

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		lxc iptables aufs-tools ca-certificates curl wget software-properties-common language-pack-en \
	&& rm -rf /var/lib/apt/lists/*

# Fix locale.
ENV LANG en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
RUN locale-gen en_US && update-locale LANG=en_US.UTF-8 LC_CTYPE=en_US.UTF-8

# grab gosu for easy step-down from root
ENV GOSU_VERSION 1.7
RUN set -x \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true

# Install openjdk-8-jdk
RUN add-apt-repository ppa:openjdk-r/ppa \
  && apt-get update \
  && apt-get -y install openjdk-8-jdk
# Install docker
ENV DOCKER_BUCKET get.docker.com
ENV DOCKER_VERSION 1.11.1
ENV DOCKER_SHA256 893e3c6e89c0cd2c5f1e51ea41bc2dd97f5e791fcfa3cee28445df277836339d
RUN set -x \
  && curl -fSL "https://${DOCKER_BUCKET}/builds/Linux/x86_64/docker-$DOCKER_VERSION.tgz" -o docker.tgz \
  && echo "${DOCKER_SHA256} *docker.tgz" | sha256sum -c - \
  && tar -xzvf docker.tgz \
  && mv docker/* /usr/local/bin/ \
  && rmdir docker \
  && rm docker.tgz \
  && docker -v

RUN groupadd docker && adduser --disabled-password --gecos "" teamcity \
	&& sed -i -e "s/%sudo.*$/%sudo ALL=(ALL:ALL) NOPASSWD:ALL/" /etc/sudoers \
	&& usermod -a -G docker,sudo teamcity

# Install jq (from github, repo contains ancient version)
RUN curl -o /usr/local/bin/jq -SL https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 \
	&& chmod +x /usr/local/bin/jq

# Install nodejs (from official node dockerfile)

# gpg keys listed at https://github.com/nodejs/node
RUN set -ex \
  && for key in \
   4ED778F539E3634C779C87C6D7062848A1AB005C \
   B9E2F5981AA6E0CD28160D9FF13993A75599653C \
   94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
   B9AE9905FFD7803F25714661B63B535A4C206CA9 \
   77984A986EBC2AA786BC0F66B01FBB92821C587A \
   71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
   FD3A5288F042B6850C66B31F09FE44734EB7990E \
   8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
   C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
   DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
  ; do \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
  done

ENV NODE_VERSION 10.15.3
ENV NPM_VERSION 6.4.1

RUN curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz" \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --verify SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-x64.tar.gz\$" SHASUMS256.txt.asc | sha256sum -c - \
  && tar -xzf "node-v$NODE_VERSION-linux-x64.tar.gz" -C /usr/local --strip-components=1 \
  && rm "node-v$NODE_VERSION-linux-x64.tar.gz" SHASUMS256.txt.asc \
  && npm install -g "npm@$NPM_VERSION"

# Install yarn
RUN apt-get install apt-transport-https
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - \
  && echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list \
  && apt-get update \
  && apt-get -y install --no-install-recommends yarn

# Install ruby build repositories
RUN apt-add-repository ppa:brightbox/ruby-ng \
	&& apt-get update \
    && apt-get upgrade -y \
	&& apt-get install -y ruby2.3 ruby2.3-dev ruby ruby-switch unzip \
	iptables lxc fontconfig libffi-dev build-essential git python-dev libssl-dev python-pip \
	&& rm -rf /var/lib/apt/lists/*

# Install httpie (with SNI), awscli, docker-compose
RUN pip install setuptools --upgrade
RUN pip install --upgrade pyopenssl pyasn1 ndg-httpsclient httpie awscli docker-compose==1.6.0
RUN ruby-switch --set ruby2.3
RUN npm install -g bower grunt-cli
RUN gem install rake bundler compass --no-ri --no-rdoc

# Install the magic wrapper.
ADD wrapdocker /usr/local/bin/wrapdocker

ADD docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

VOLUME /var/lib/docker
VOLUME /opt/buildAgent


EXPOSE 9090
