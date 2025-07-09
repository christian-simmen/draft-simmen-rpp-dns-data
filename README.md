# DNS data representation for use in RESTful Provisioning Protocol (RPP)

## Overview
This document proposes a unified, extensible JSON representation for DNS resource records for use in the RESTful Provisioning Protocol (RPP). The aim is to create a single, consistent structure for provisioning all DNS-related data - including delegation, DNSSEC, and other record types - that directly mirrors the DNS data model and being mappable to existing EPP model of requests and responses same time. This approach simplifies the adoption of both current and future DNS features by aligning the provisioning format with the target system, thereby streamlining the management of domain names and related objects within RPP.

## Contributing
This draft is open for contributions and comments. We welcome feedback and suggestions to improve the architecture. To contribute, please submit a pull request or open an issue in this repository.

## Generating IETF I-D
`draft-simmen-rpp-dns-data*.md` file is the source file to generate I-D.

In order to generate I-D documents the following script [generate.sh](./generate.sh) is provided.

Required tools:
- xml2rfc
- kramdown-rfc

The [.devcontainer](./.devcontainer) folder contains configuration for [VSCode Dev Container extension](https://code.visualstudio.com/docs/devcontainers/containers) with corresponding [Dockerfile](./.devcontainer/Dockerfile) including all necessary tools.

## Publishing IETF I-D

A detailed documentation can be found in the [Internet-Draft Author Resources](https://authors.ietf.org/en/getting-started)

- [Ensure it has all the required content](https://authors.ietf.org/required-content)
- Generate documents
- [Validate your I-D](https://authors.ietf.org/document-validation) unsing the [IETF Author Tools](https://author-tools.ietf.org/)
- [Submit your I-D to Datatracker](https://authors.ietf.org/en/submitting-your-internet-draft) using the [IETF Datatracker's submission tool](https://datatracker.ietf.org/submit/)
