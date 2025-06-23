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
title: "DNS data representation for use in RESTful Provisioning Protocol (RPP)"
abbrev: "RPP DNS"
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
  mail: rpp@ietf.org
  arch: https://mailarchive.ietf.org/arch/browse/rpp/
  github: christian-simmen/draft-simmen-rpp-dns-data
  latest: https://github.com/christian-simmen/draft-simmen-rpp-dns-data
  #latest: https://datatracker.ietf.org/doc/draft-simmen-rpp-dns-data

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

This document proposes a representation for various DNS data for use in the RESTful Provisioning Protocol (RPP). Specified in JSON, the document describes common DNS record types used for domain provisioning as well as giving advice on how to adopt future record types.

EPP focused on distinct host objects containing data used for delegation purposes {{RFC5732}} and a separate extension focused on transferring DNSSEC relevant data {{RFC5910}}. Current registry system implementations improve these by grouping name servers into a nsset, or allowing domain provisioning without delegation. In addition new delegation mechanisms are developed {{I-D.draft-ietf-deleg}} to achieve a faster name resolution by providing properties of the child name server at delegation time.

Regardless of the specific use case all of the above data is meant to become visible in DNS. For this a structure close to the targeted system (DNS) makes it easy to adopt to current and future developments.



--- middle

# Introduction

In EPP host objects {{RFC5732}} are introduced. In the context of domain name service provisioning those objects are used as delegation information (NS) with optional GLUE (A) records. By the time of writing new transport protocols are used for DNS like DNS over HTTPS {{RFC8484}} or DNS over QUIC {{RFC9250}}. Along with this development the need for more fine grained delegation information is emerging. The DELEG record type {{I-D.draft-ietf-deleg}} can be seen as an example.

Apart from plain delegation information other DNS related data like DNSSEC information is common to be provisioned through EPP {{RFC5910}}.

Some current registry system implementations are further improving the
management of dns data. For example FRED (CZ.NIC) is grouping name servers into name server sets. RRI (DENIC) provides an option to provision a delegation-less domain by storing other DNS record types at the registry.

For all of the mentioned data is meant to be visible in DNS shifting from managing host objects to managing DNS data of a domain object will give an adavantage for adopting future resource record types as well covering current use cases.


## Domain Names in DNS

DNS domain names are hierarchically ordered label separated by a dot ".". Each label represent the delegation of a subordinate namespace or a host name. DNS resource records {{RFC1035}} are expressed as a dataset containing:

"NAME" "CLASS" "TYPE" "TTL" "RDLENGTH" "RDATA"

A set of resource records describes the behavior of a namespace. Each resource record shares the same top level format.

NAME      The owner name of the DNS entry which MAY be the domain itself or a subordinate hostname.

CLASS     The RR CLASS

TYPE      The RR TYPE of data present in the RDATA field.

TTL       Time interval a RR may be cached by name servers

RDLENGTH  The length of the RDATA field. RDLENGTH will be safely ignored in RPP

RDATA     The actual payload data. Structures defer for each type.


## JSON representation

### Rules

#### Extending the RPP Domain object
Delegation data, as well as DNSSEC data, is intended to find it's way into the parent side DNS servers. Because of the strong connection to the provisioned domain object and DNS servers both aspects should be visible in the RPP data model. Therefore the domain object is extended by an array of DNS entries. The properties of an object in this array MUST be a representation of the top level format as described in section 3.2.1 of {{RFC1035}}. All keys MUST be lowercase. Whitespaces MUST be translated to underscores ("_").

~~~~
    {
      "domain": "example.com",
      "dns": [
        {
          "name": "",
          "class": "",
          "type": "",
          "ttl": "",
          "rdata": {}
        }
      ]
    }
~~~~

#### "name"

The owner name of the DNS entry which MAY be the domain itself or a subordinate hostname. A server MUST NOT accept a NAME which is not a subordinate label to the provisioned domain name.

A server MUST accept values as "@", "relative names" and fully qualified domain names (FQDN).

"@" MUST be interpreted as the provisioned domain name.

"relative names" MUST be appended by the server with the provisioned domain name.

"FQDN" identified by a trailing dot (".") MUST NOT be interpreted by the server. A server MUST check if the provided name is a subordinate to the provisioned domain, or the domain itself.

Example:
~~~~
    {
      "domain": "example.com",
      "dns": [
        {
          "name": "@",
          "type": "A",
          "rdata": {
            "address": "1.1.1.1"
          }
        },
        {
          "name": "www",
          "type": "A",
          "rdata": {
            "address": "2.2.2.2"
          }
        },
        {
          "name": "web.example.com.",
          "type": "A",
          "rdata": {
            "address": "3.3.3.3"
          }
        }
      ]
    }
~~~~
would imply three resulting records:
An A RR for "example.com" ("@") set to 1.1.1.1.
An A RR for "www.example.com" ("www" relative) set to 2.2.2.2.
An A RR for "web.example.com" (FQDN) set to 3.3.3.3.



##### "class"

A client SHOULD omit the class. The server MUST assume "IN" as class of a transferred dataset and MAY decline other values.
If present the value MUST be chosen from section 3.2.4. CLASS values of {{RFC1035}}.

##### "type"

The TYPE of data present in the RDATA. This also implies the expected fields in RDATA.
If present the value MUST chosen from section 3.2.2. TYPE values of {{RFC1035}} or other RFC describing the RR TYPE.

##### "ttl"

A server MUST set a default value as TTL and MAY decline other values. A client SHOULD omit this value.

##### "rdlength"

RDLENGTH specifies the length of the RDATA field and will be ignored in RPP. A client MUST NOT include this field. A server MUST ignore this field if present.

##### "rdata"

The RDATA structure depends on the TYPE and MUST be expressed as a JSON object. Property names MUST follow the definition of the RDATA described by the corresponding RFC. Property names MUST be translated to lowercase. Whitespaces MUST be translated to underscores ("_").

Example:
Section 3.3.11 NS RDATA format of {{RFC1035}} describes the RDATA of a NS RR as "NSDNAME".
Section 3.3.9 MX RDATA format of {{RFC1035}} describes the RDATA of a MX RR as "PREFERENCE", "EXCHANGE".
The resulting structure is therefore:
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
          "type": "MX",
          "rdata": {
            "preference": "10",
            "exchange": "mx1.example.net"
          }
        }
      ]
    }
~~~~

#### Additional controls

In addition to the regular data a server MAY allow a client to control specific operational behavior.
A client MAY add an JSON object with a number of "controls" to the DNS dataset.

~~~~
    {
      "domain": "example.com",
      "dns": [
        {
          "name": "<name>",
          "type": "<type>",
          "rdata": {
            "rdata_key": "<rdata_value>",
          }
          "controls": {
            "<named_control>": "<named_control_value>"
          }
        }
      ]
    }
~~~~

### Domain delegation

To enable domain delegation a server MUST support the "NS", "A" and "AAAA" record types ({{RFC1035}},{{RFC3596}}).

A minimal delegation can be expressed by adding an array of name servers to the DNS data of a domain:

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
          "name": "ns.example.com.",
          "type": "A",
          "rdata": {
            "address": "1.2.3.4"
          }
        },
        {
          "name": "ns.example.com.",
          "type": "AAAA",
          "rdata": {
            "address": "dead::beef"
          }
        }
      ]
    }
~~~~

### DNSSEC

To enable DNSSEC provisioning a server SHOULD support either "DS" or "DNSKEY" or both record types. The records MUST be added to the "dns" array of the domain. If provided with only "DNSKEY" a server MUST calculate the DS record. If both record types are provided a server MAY use the DNSKEY to validate the DS record.

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
      "domain": "example.com.",
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

#### Maximum signature lifetime
Maximum signature lifetime (maximum_signature_lifetime) describes the maximum number of seconds after signature generation a parents signature on signed DNS information should expire. The maximum_signature_lifetime value applies to the RRSIG resource record (RR) over the signed DNS RR. See Section 3 of {{RFC4034}} for information on the RRSIG resource record (RR).

A client MAY add maximum_signature_lifetime to the controls of an entry which is intended to be signed on the parent side. A server MAY ignore this value, e.g. for policy reasons.

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
          },
          "controls": {
            "maximum_signature_lifetime": 86400
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
      "name": "www.example.com.",
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
      "name": "www.example.com.",
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
      "name": "mx1.example.com.",
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

### Future DNS record types

Future record types SHOULD be added by breaking down the RDATA field specified by the RFC of the corresponding DNS record type.

## Signaling supported record types
The server MUST provide a list of supported record types to the client.

# Conventions and Definitions

{::boilerplate bcp14-tagged}


# Security Considerations

A server SHOULD choose the supported record types wisely and MAY restrict the number of accepted entries.
Also see security considerations of {{RFC4627}}.


# IANA Considerations

This document has no IANA actions.

# Appendix


--- back

# Acknowledgments
{:numbered="false"}
