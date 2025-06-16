---
###
# Internet-Draft Markdown Template
#
# Rename this file from draft-todo-yourname-protocol.md to get started.
# Draft name format is "draft-<yourname>-<workgroup>-<name>.md".
#
# For initial setup, you only need to edit the first block of fields.
# Only "title" needs to be changed; delete "abbrev" if your title is short.
# Any other content can be edited, but be careful not to introduce errors.
# Some fields will be set automatically during setup if they are unchanged.
#
# Don't include "-00" or "-latest" in the filename.
# Labels in the form draft-<yourname>-<workgroup>-<name>-latest are used by
# the tools to refer to the current version; see "docname" for example.
#
# This template uses kramdown-rfc: https://github.com/cabo/kramdown-rfc
# You can replace the entire file if you prefer a different format.
# Change the file extension to match the format (.xml for XML, etc...)
#
###
title: "Provisioning of DNS data through RPP"
#abbrev: "RPP DNS" #TODO Kurzname
category: info

docname: draft-simmen-rpp-dns-data-00
submissiontype: IETF  # also: "independent", "editorial", "IAB", or "IRTF"
number:
date: 2025-06-10
consensus: false
v: 3
area: Applications and Real-Time
workgroup: rpp
keyword:
 - rpp
 - epp
 - json
 - provisioning
 - host
venue:
  group: WG
  type: Working Group
  mail:	rpp@ietf.org
  arch: https://mailarchive.ietf.org/arch/browse/rpp/
  github: christian-simmen/draft-simmen-rpp-dns-data-representation #TODO finales Repo
  latest: https://github.com/christian-simmen/draft-simmen-rpp-dns-data-representation #TODO finales Repo
  #latest: https://datatracker.ietf.org/doc/draft-simmen-rpp-dns-data-representation #TODO finales Repo

author:
 -
    fullname: Christian Simmen
    organization: DENIC eG
    email: simmen@denic.de

normative:
  RFC5730:

# * RRP Architectural
# * RPP Requirements

informative:
# * RDAP DNS?
  I-D.draft-bortzmeyer-dns-json-01:
...

--- abstract

This document proposes an RESTful Provisioning Protocol (RPP) mapping for the provisioning of various DNS data. Specified in JSON, the mapping is decibes common DNS record types used for domain provisioning as well as giving advice on how to adopt future record types.


--- middle

# Introduction

In EPP host objects {{!RFC5732}} are introduced. In the context of domain name service provisioning those objects are used as delegation information (NS) with optional GLUE (A) records. By the time of writing new transport protocols are used for DNS like DNS over HTTPS {{?RFC8484}} or DNS over QUIC {{?RFC9250}}. Along with this development the need for more fine grained delegation information is emerging. The DELEG record type {{?I-D.draft-ietf-deleg}} can be seen as an example.
Apart from plain delegation information other DNS related data like DNSSEC {{!RFC5910}} information is common to be provisioned through EPP.

## Domain Names in DNS

DNS domain names are hierachically ordered label separated by a dot ".". Each label may represent the delegation of a subordinate namespace or a host name. DNS resource records {{!RFC1035}} are expressed as a dataset containing:

"NAME" "CLASS" "TYPE" "TTL" "RDATA"

A set of resource records describes the behavior of namespace.

### NAME

A server MUST only accept a NAME which is a subordinate label to the provisioned domain name or "@" representing the provisioned domain itself.

### CLASS

A client SHOULD omit the CLASS. The server MUST assume "IN" as CLASS of a transferred dataset an MAY decline other values.

### TYPE

The TYPE of data present in the RDATA. This also implies the expected fields in RDATA.

### TTL

A server MUST set a default value as TTL and MAY decline other values. A client MAY omit this value.

### RDATA

The RDATA depends on the TYPE. A RR of TYPE "NS" has the hostname of an authorative nameserver. A RR of TYPE "AAAA" holds the IPv6 address of a host. A RR of TYPE "DS" has multiple fields (key tag, key algorithm, the digest hash type and the digest hash)

## JSON mapping

A minimal delegation can be expressed by adding an array of nameservers to dns data of a domain:

{
  domain: "example.com"
  "dns": [
    {"name": "@", "type": "NS", "rdata": {"host": "ns1.example.net"}},
    {"name": "@", "type": "NS", "rdata": {"host": "ns2.example.net"}}
  ]
}

If GLUE records are needed the client may add these records:

{
  domain: "example.com"
  "dns": [
    {"name": "@", "type": "NS", "rdata": {"host": "ns1.example.net"}},
    {"name": "@", "type": "NS", "rdata": {"host": "ns2.example.com"}},
    {"name": "ns2.example.com", "type": "A", "rdata": {"address": "1.2.3.4"}},
    {"name": "ns2.example.com", "type": "AAAA", "rdata": {"address": "dead::beef"}}
  ]
}


The provisioning of DNSSEC further extends the structure:

{
  domain: "example.com"
  "dns": [
    {"name": "@", "type": "NS", "rdata": {"host": "ns1.example.net"}},
    {"name": "@", "type": "NS", "rdata": {"host": "ns2.example.com"}},
    {"name": "ns2.example.com", "type": "A", "rdata": {"address": "1.2.3.4"}},
    {"name": "ns2.example.com", "type": "AAAA", "rdata": {"address": "dead::beef"}},
    {"name": "@", "type": "DS", "rdata": {
                                    "key_tag": "1234",
                                    "key_algorithm": 13,
                                    "digest_hash_type": 2,
                                    "digest_hash": "F341357809A5954311CCB82ADE114C6C1D724A75C0395137AA397803 5425E78D"
                                    }
    }
  ]
}


### Well known RR types

TODO Liste der RR aus wiki holen und namen definieren


### Future DNS record types
TODO

Beschreibung wie zukünftige RR Types abgebildet werden können

## Signaling supported record types
A server MUST support the "NS", "A" and "AAAA" record type. A server SHOULD support "DS" record type. Additional record types MAY be supported by a server. The server MUST provide which record types are supported.

TODO Review


# Conventions and Definitions

{::boilerplate bcp14-tagged}


# Security Considerations

TODO Security


# IANA Considerations

This document has no IANA actions.


--- back

# Acknowledgments
{:numbered="false"}

TODO acknowledge.
