FROM ubuntu:18.04

ENV SOLR_GROUP solr
ENV SOLR_USER solr
ENV SOLE_UID 8983
ENV HOME /home/${SOLR_USER}

RUN apt-get update && \
    apt-get install -y openjdk-8-jdk && \
    apt-get install -y iproute2 nano curl netcat lsof jq libxml2-utils xmlstarlet tar && \
    apt-get clean && \
    mkdir ${HOME} && \
    groupadd -r ${SOLR_GROUP} && \
    useradd -u ${SOLE_UID} -g ${SOLR_GROUP} -d ${HOME} ${SOLR_USER} && \
    chown -R ${SOLR_USER}:${SOLR_GROUP} ${HOME}

USER ${SOLR_USER}
WORKDIR ${HOME}

# Create directories for persistent data
RUN mkdir -p ${HOME}/data/solr

ENV SOLR_VERSION 5.5.5
RUN curl -L -o ${HOME}/solr-${SOLR_VERSION}.tgz http://archive.apache.org/dist/lucene/solr/${SOLR_VERSION}/solr-${SOLR_VERSION}.tgz && \
    tar -C ${HOME} -xf ${HOME}/solr-${SOLR_VERSION}.tgz && \
    rm ${HOME}/solr-${SOLR_VERSION}.tgz

ENV SOLR_PREFIX ${HOME}/solr-${SOLR_VERSION}

# Create initialization script for Solr home
RUN echo '#!/bin/bash' > ${HOME}/init-solr-home.sh && \
    echo 'if [ ! -f /home/solr/solr-5.5.5/server/solr/solr.xml ]; then' >> ${HOME}/init-solr-home.sh && \
    echo '  echo "Initializing Solr home directory..."' >> ${HOME}/init-solr-home.sh && \
    echo '  cp -r /home/solr/solr-5.5.5/server/solr-original/* /home/solr/solr-5.5.5/server/solr/ 2>/dev/null || true' >> ${HOME}/init-solr-home.sh && \
    echo '  if [ ! -f /home/solr/solr-5.5.5/server/solr/solr.xml ]; then' >> ${HOME}/init-solr-home.sh && \
    echo '    cat > /home/solr/solr-5.5.5/server/solr/solr.xml << '\''EOF'\''' >> ${HOME}/init-solr-home.sh && \
    echo '<?xml version="1.0" encoding="UTF-8" ?>' >> ${HOME}/init-solr-home.sh && \
    echo '<solr></solr>' >> ${HOME}/init-solr-home.sh && \
    echo 'EOF' >> ${HOME}/init-solr-home.sh && \
    echo '  fi' >> ${HOME}/init-solr-home.sh && \
    echo 'fi' >> ${HOME}/init-solr-home.sh && \
    chmod +x ${HOME}/init-solr-home.sh

# Backup the original solr directory
RUN cp -r ${HOME}/solr-${SOLR_VERSION}/server/solr ${HOME}/solr-${SOLR_VERSION}/server/solr-original

EXPOSE 8983 7983 18983

CMD ["/usr/local/bin/docker-run.sh"]