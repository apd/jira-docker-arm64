ARG BASE_IMAGE=adoptopenjdk:8-hotspot
FROM $BASE_IMAGE

ENV RUN_USER                                        jira
ENV RUN_GROUP                                       jira
ENV RUN_UID                                         2001
ENV RUN_GID                                         2001

# https://confluence.atlassian.com/display/JSERVERM/Important+directories+and+files
ENV JIRA_HOME                                       /var/atlassian/application-data/jira
ENV JIRA_INSTALL_DIR                                /opt/atlassian/jira

WORKDIR $JIRA_HOME

EXPOSE 8080

CMD ["/entrypoint.py"]
ENTRYPOINT ["/tini", "--"]

RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends fontconfig python3 python3-jinja2 \
    && apt-get clean autoclean && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*

ARG TINI_VERSION=v0.19.0
RUN arch=$(dpkg --print-architecture); \
    case "$arch" in \
       arm64) export ARCH="-arm64" ;; \
       *) export ARCH="" ;; \
    esac; \
    url="https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini${ARCH}" ; \
    curl "$url" -Lo /tini ; \
    chmod +x /tini

ARG MYSQL_DRIVER_VERSION=5.1.49
RUN export JIRA_LIB=$JIRA_INSTALL_DIR/lib                      \
    && mkdir -p $JIRA_LIB                                      \
    && export MYSQL_FILE_BASE=mysql-connector-java-$MYSQL_DRIVER_VERSION \
    && export MYSQL_FILE_TAR=$MYSQL_FILE_BASE.tar.gz           \
    && export MYSQL_FILE_BIN=$MYSQL_FILE_BASE-bin.jar          \
    && export MYSQL_DOWNLOAD_URL=https://dev.mysql.com/get/Downloads/Connector-J/$MYSQL_FILE_TAR \
    && rm -f $JIRA_LIB/mysql-connector-java*.jar               \
    && curl $MYSQL_DOWNLOAD_URL -Lo $MYSQL_FILE_TAR            \
    && tar xzf $MYSQL_FILE_TAR --strip=1                       \
    && cp $MYSQL_FILE_BIN $JIRA_LIB/$MYSQL_FILE_BIN

ARG JIRA_VERSION

# The link may change from version to version, check
# https://www.atlassian.com/ru/software/jira/download-archives
ARG DOWNLOAD_URL=https://product-downloads.atlassian.com/software/jira/downloads/atlassian-jira-software-${JIRA_VERSION}.tar.gz

RUN groupadd --gid ${RUN_GID} ${RUN_GROUP} \
    && useradd --uid ${RUN_UID} --gid ${RUN_GID} --home-dir ${JIRA_HOME} --shell /bin/bash ${RUN_USER} \
    && echo PATH=$PATH > /etc/environment \
    \
    && mkdir -p                                     ${JIRA_INSTALL_DIR} \
    && curl -L --silent                             ${DOWNLOAD_URL} | tar -xz --strip-components=1 -C "${JIRA_INSTALL_DIR}" \
    && chmod -R "u=rwX,g=rX,o=rX"                   ${JIRA_INSTALL_DIR}/ \
    && chown -R root.                               ${JIRA_INSTALL_DIR}/ \
    && chown -R ${RUN_USER}:${RUN_GROUP}            ${JIRA_INSTALL_DIR}/logs \
    && chown -R ${RUN_USER}:${RUN_GROUP}            ${JIRA_INSTALL_DIR}/temp \
    && chown -R ${RUN_USER}:${RUN_GROUP}            ${JIRA_INSTALL_DIR}/work \
    \
    && sed -i -e 's/^JVM_SUPPORT_RECOMMENDED_ARGS=""$/: \${JVM_SUPPORT_RECOMMENDED_ARGS:=""}/g' ${JIRA_INSTALL_DIR}/bin/setenv.sh \
    && sed -i -e 's/^JVM_\(.*\)_MEMORY="\(.*\)"$/: \${JVM_\1_MEMORY:=\2}/g' ${JIRA_INSTALL_DIR}/bin/setenv.sh \
    && sed -i -e 's/-XX:ReservedCodeCacheSize=\([0-9]\+[kmg]\)/-XX:ReservedCodeCacheSize=${JVM_RESERVED_CODE_CACHE_SIZE:=\1}/g' ${JIRA_INSTALL_DIR}/bin/setenv.sh \
    \
    && touch /etc/container_id \
    && chown ${RUN_USER}:${RUN_GROUP}               /etc/container_id \
    && chown -R ${RUN_USER}:${RUN_GROUP}            ${JIRA_HOME}

# Must be declared after setting perms
VOLUME ["${JIRA_HOME}"]

COPY components/entrypoint/                  /
COPY components/support/                     /opt/atlassian/support
COPY components/config/                      /opt/atlassian/etc/
