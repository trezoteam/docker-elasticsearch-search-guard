# Elasticsearch with Search Guard (6.6.1)

This repository contains the Dockerfile to build an image containing elasticsearch 6.6.1 with the Search Guard 6.6.1-24.1 plugin installed.

## Installation

You can build it locally after cloning and use your local image:
```
git clone https://github.com/trezoteam/docker-elasticsearch-search-guard.git
cd docker-elasticsearch-search-guard
build .
```
Or run the image available on Docker Hub directly:
```
docker run trezoinfra/elasticsearch-search-guard
```
## Usage

Running the image will result in an Elasticsearch instance protected by Search Guard. You can test this by running a curl to ES, and Search Guard will return "**Unauthorized**"
```
$ curl 127.0.0.1:9200
Unauthorized
```

If you authenticate with the default "admin" user, however:

```
$ curl 127.0.0.1:9200 -uadmin:admin
{
  "name" : "k8g6m6l",
  "cluster_name" : "docker-cluster",
  "cluster_uuid" : "YQJZgLQoQJ-qyBYeJoMvUA",
  "version" : {
    "number" : "6.6.1",
    "build_flavor" : "default",
    "build_type" : "tar",
    "build_hash" : "1fd8f69",
    "build_date" : "2019-02-13T17:10:04.160291Z",
    "build_snapshot" : false,
    "lucene_version" : "7.6.0",
    "minimum_wire_compatibility_version" : "5.6.0",
    "minimum_index_compatibility_version" : "5.0.0"
  },
  "tagline" : "You Know, for Search"
}
```

### Volumes
Search Guard makes it mandatory to use TLS certificate and keys for node communication. This image automatically generates the required files and appends the generated configuration to elasticsearch.yml. 

We recommend a volume mount for both the **/usr/share/elasticsearch/config/elasticsearch.yml** file as well as one for the directory containing TLS files the entrypoint outputs, which is **/usr/share/elasticsearch/config/tls** so that you don't lose the files nor the configuration related to TLS.

## Contributing
This repository was created due to an internal company need. We may not look at Pull Requests frequently, but please feel free to report issues and propose code changes.

## License
[MIT](https://choosealicense.com/licenses/mit/)
