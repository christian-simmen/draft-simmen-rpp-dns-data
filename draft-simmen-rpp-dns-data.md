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
title: "DNS data mapping for use in RESTful Provisioning Protocol (RPP)"
#abbrev: "RPP DNS" #TODO Kurzname
category: info

docname: draft-simmen-rpp-dns-data-00
submissiontype: IETF  # also: "independent", "editorial", "IAB", or "IRTF"
number:
date: 2025-06-17
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
  github: christian-simmen/draft-simmen-rpp-dns-data #TODO finales Repo
  latest: https://github.com/christian-simmen/draft-simmen-rpp-dns-data #TODO finales Repo
  #latest: https://datatracker.ietf.org/doc/draft-simmen-rpp-dns-data #TODO finales Repo

author:
 -
    fullname: Christian Simmen
    organization: DENIC eG
    email: simmen@denic.de

normative:
  RFC1035:
  RFC4627:
  RFC5730:
  RFC5732:

# * RRP Architectural
# * RPP Requirements

informative:
# * RDAP DNS?
  RFC3596:
  RFC4034:
  RFC8484:
  RFC5910:
  RFC9250:
  I-D.draft-ietf-deleg:
  I-D.draft-bortzmeyer-dns-json-01:
...

--- abstract

This document proposes an RESTful Provisioning Protocol (RPP) mapping for the provisioning of various DNS data. Specified in JSON, the mapping is decibes common DNS record types used for domain provisioning as well as giving advice on how to adopt future record types.


--- middle

# Introduction

In EPP host objects {{RFC5732}} are introduced. In the context of domain name service provisioning those objects are used as delegation information (NS) with optional GLUE (A) records. By the time of writing new transport protocols are used for DNS like DNS over HTTPS {{RFC8484}} or DNS over QUIC {{RFC9250}}. Along with this development the need for more fine grained delegation information is emerging. The DELEG record type {{I-D.draft-ietf-deleg}} can be seen as an example.
Apart from plain delegation information other DNS related data like DNSSEC information is common to be provisioned through EPP {{RFC5910}}.

## Domain Names in DNS

DNS domain names are hierachically ordered label separated by a dot ".". Each label may represent the delegation of a subordinate namespace or a host name. DNS resource records {{RFC1035}} are expressed as a dataset containing:

"NAME" "CLASS" "TYPE" "TTL" "RDATA"

A set of resource records describes the behavior of namespace.

### NAME

A server MUST NOT accept a NAME which is not a subordinate label to the provisioned domain name or "@" representing the provisioned domain itself.

### CLASS

A client SHOULD omit the CLASS. The server MUST assume "IN" as CLASS of a transferred dataset an MAY decline other values.

### TYPE

The TYPE of data present in the RDATA. This also implies the expected fields in RDATA.

### TTL

A server MUST set a default value as TTL and MAY decline other values. A client MAY omit this value.

### RDATA

The RDATA structure depends on the TYPE and MUST be expressed as a JSON object. Property names MUST follow the definition of the RDATA described by the coresponding RFC.

## JSON mapping

### Domain delegation

To enable domain delegation a server MUST support the "NS", "A" and "AAAA" record types ({{RFC1035}},{{RFC3596}}).

A minimal delegation can be expressed by adding an array of nameservers to the dns data of a domain:

TODO Discuss naming "nsdname" vs. "host" vs "nameserver"

~~~~
    {
      "domain": "example.com",
      "dns": [
        {
          "name": "@",
          "type": "NS",
          "rdata": {
            "nsdname": "a.iana-servers.net."
          }
        },
        {
          "name": "@",
          "type": "NS",
          "rdata": {
            "nsdname": "b.iana-servers.net."
          }
        }
      ]
    }
~~~~

If GLUE records are needed the client may add records of type "A" or "AAAA" :

~~~~
    {
      "domain": "example.com",
      "dns": [
        {
          "name": "@",
          "type": "NS",
          "rdata": {
            "nsdname": "a.iana-servers.net."
          }
        },
        {
          "name": "@",
          "type": "NS",
          "rdata": {
            "nsdname": "ns.example.com"
          }
        },
        {
          "name": "ns.example.com",
          "type": "A",
          "rdata": {
            "address": "1.2.3.4"
          }
        },
        {
          "name": "ns.example.com",
          "type": "AAAA",
          "rdata": {
            "address": "dead::beef"
          }
        }
      ]
    }
~~~~

### DNSSEC

To enable DNSSEC provisioning a server SHOULD support either "DS" or "DNSKEY" or both record types. The records MUST be added to the "dns" array of the domain

~~~~
    {
      "domain": "example.com",
      "dns": [
        {
          "name": "@",
          "type": "NS",
          "rdata": {
            "nsdname": "a.iana-servers.net."
          }
        },
        {
          "name": "@",
          "type": "NS",
          "rdata": {
            "nsdname": "b.iana-servers.net."
          }
        },
        {
          "name": "@",
          "type": "DS",
          "rdata": {
            "key_tag": "370",
            "algorithm": 13,
            "digest_type": 2,
            "digest": "BE74359954660069D5C63D200C39F5603827D7DD02B56F120EE9F3A86764247C"
          }
        }
      ]
    }
~~~~

~~~~
    {
      "domain": "example.com",
      "dns": [
        {
          "name": "@",
          "type": "NS",
          "rdata": {
            "nsdname": "a.iana-servers.net."
          }
        },
        {
          "name": "@",
          "type": "NS",
          "rdata": {
            "nsdname": "b.iana-servers.net."
          }
        },
        {
          "name": "@",
          "type": "DNSKEY",
          "rdata": {
            "flags": 257,
            "protocol": 3,
            "algorithm": 13,
            "public_key": "kXKkvWU3vGYfTJGl3qBd4qhiWp5aRs7YtkCJxD2d+t7KXqwahww5IgJtxJT2yFItlggazyfXqJEVOmMJ3qT0tQ=="
          }
        }
      ]
    }
~~~~

### Other DNS data

A server MAY support additional RR types, e.g. to support delegation-less provisioning.

~~~~
{
  "domain": "example.com",
  "dns": [
    {
      "name": "@",
      "type": "A",
      "rdata": {
        "address": "1.2.3.4"
      }
    },
    {
      "name": "www.example.com",
      "type": "A",
      "rdata": {
        "address": "1.2.3.4"
      }
    },
    {
      "name": "@",
      "type": "AAAA",
      "rdata": {
        "address": "dead::beef"
      }
    },
    {
      "name": "www.example.com",
      "type": "A",
      "rdata": {
        "address": "dead::beef"
      }
    },
    {
      "name": "@",
      "type": "MX",
      "rdata": {
        "preference": "10",
        "exchange": "mx1.example.com"
      }
    },
    {
      "name": "mx1.example.com",
      "type": "A",
      "rdata": {
        "address": "5.6.7.8"
      }
    },
    {
      "name": "@",
      "type": "MX",
      "rdata": {
        "preference": "20",
        "exchange": "mx2.example.net"
      }
    },
    {
      "name": "@",
      "type": "TXT",
      "rdata": {
        "txt_data": "v=spf1 -all"
      }
    }
  ]
}
~~~~

TODO Discuss enforcement of FQDN in "name", "nsdname" and "exchange"


### Future DNS record types

Future record types may be added in the same way


## Signaling supported record types
The server MUST provide a list of supported record types to the client.

TODO Add signaling to general signaling of server capabilities


# Conventions and Definitions

{::boilerplate bcp14-tagged}


# Security Considerations

A server SHOULD choose the supported record types wisely and MAY restrict the number of accepted entries.
Also see security considerations of {{RFC4627}}.


# IANA Considerations

This document has no IANA actions.


--- back

# Acknowledgments
{:numbered="false"}
