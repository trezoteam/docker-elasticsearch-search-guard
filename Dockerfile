FROM elasticsearch:6.6.1

RUN echo 'xpack.security.enabled: false' >> config/elasticsearch.yml 
RUN echo 'searchguard.enterprise_modules_enabled: false' >> config/elasticsearch.yml 

# https://docs.search-guard.com/latest/search-guard-versions
ENV SEARCH_GUARD_MAJOR "6"
ENV SEARCH_GUARD_VERSION "6.6.1-24.1"
ENV SEARCH_GUARD_ZIP "/tmp/search-guard-kibana-plugin-${SEARCH_GUARD_VERSION}.zip"

RUN curl -o "${SEARCH_GUARD_ZIP}" \
    "https://oss.sonatype.org/service/local/repositories/releases/content/com/floragunn/search-guard-${SEARCH_GUARD_MAJOR}/${SEARCH_GUARD_VERSION}/search-guard-${SEARCH_GUARD_MAJOR}-${SEARCH_GUARD_VERSION}.zip"

RUN bin/elasticsearch-plugin install -b "file://${SEARCH_GUARD_ZIP}"

RUN echo "export PATH=$PWD/plugins/search-guard-${SEARCH_GUARD_MAJOR}"'/tools/:$PATH' >> /etc/bashrc && chmod +x plugins/search-guard-${SEARCH_GUARD_MAJOR}/tools/sgadmin.sh

COPY entrypoint.sh /entrypoint.sh
RUN chmod u+x /entrypoint.sh

CMD ["/entrypoint.sh"]
