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
abbrev: "RPP DNS data representation"
category: info

docname: draft-simmen-rpp-dns-data-00
submissiontype: IETF  # also: "independent", "editorial", "IAB", or "IRTF"
number:
date: 2025-07-07
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
    country: DE
    email: simmen@denic.de

 -
    fullname: Pawel Kowalik
    organization: DENIC eG
    country: DE
    email: pawel.kowalik@denic.de


normative:
  RFC1035:
  RFC5731:
  RFC5732:
  RFC5910:
  RFC9803:
  RFC3596:
  RFC4034:
  RFC9083:

informative:
  RFC8484:
  RFC9250:
  RFC9499:
  I-D.draft-ietf-deleg:
  I-D.draft-ietf-rpp-requirements:
  #I-D.draft-ietf-regext-epp-delete-bcp:
  #I-D.draft-kowalik-rpp-architecture:
  I-D.draft-brown-rdap-ttl-extension:
...

--- abstract

This document proposes a unified, extensible JSON representation for DNS resource records for use in the RESTful Provisioning Protocol (RPP). The aim is to create a single, consistent structure for provisioning all DNS-related data - including delegation, DNSSEC, and other record types - that directly mirrors the DNS data model and being mappable to existing EPP model of requests and responses same time. This approach simplifies the adoption of both current and future DNS features by aligning the provisioning format with the target system, thereby streamlining the management of domain names and related objects within RPP.

--- middle

# Introduction

The Extensible Provisioning Protocol (EPP) manages DNS delegation data using distinct object types and extensions. Host Objects {{RFC5732}} are used for name servers (NS records) and their associated addresses (glue A/AAAA records), while DNSSEC data is handled via a separate security extension {{RFC5910}}. Name server information can be also directly attached to a domain name as a set of Host Attributes {{RFC5731}}. More recently, control over Time-to-Live (TTL) values was added through another extension {{RFC9803}}.

While functional, this segmented approach creates complexity. The DNS landscape itself is evolving, with new transport protocols like DNS-over-HTTPS {{RFC8484}} and DNS-over-QUIC {{RFC9250}} driving the need for more sophisticated delegation information, such as the proposed DELEG record type {{I-D.draft-ietf-deleg}}.

Some registry operators have developed their own proprietary solutions. These include grouping name servers into "sets" for easier management or allowing domains to be provisioned with arbitrary DNS resource records (RR) without formal delegation, which is expanding on Host Attribute model with other resource record types.

The development of the RESTful Provisioning Protocol (RPP) provides an opportunity to address this fragmentation. This document proposes a unified data representation for all DNS-related information, specified in a format that directly mirrors DNS resource records. This approach is not intended to influence existing registry data models, but rather to offer a flexible and consistent structure for the data in the protocol. By unifying the representation of delegation data (NS, A/AAAA glue), DNSSEC information, and other record types, this model can be applied across various contexts. It is designed to be equally applicable whether a registry uses separate host objects, host attributes within a domain, or more abstract concepts like name server sets, thereby simplifying implementation and ensuring adaptability for future developments in the DNS.

# Domain Names in DNS

DNS domain names are hierarchically ordered label separated by a dot ".". Each label represent the delegation of a subordinate namespace or a host name. DNS resource records {{RFC1035}} are expressed as a dataset containing:

"NAME" "CLASS" "TYPE" "TTL" "RDLENGTH" "RDATA"

A set of resource records describes the behavior of a namespace. Each resource record shares the same top level format.

NAME      The owner name of the DNS entry which MAY be the domain itself or a subordinate hostname.

CLASS     The RR CLASS

TYPE      The RR TYPE of data present in the RDATA field.

TTL       Time interval a RR may be cached by name servers

RDLENGTH  The length of the RDATA field. RDLENGTH will be safely ignored in RPP

RDATA     The actual payload data. Structures defer for each type.


# JSON representation

## Rules

### DNS data extending an domain object
Delegation data, as well as DNSSEC data, is intended to find it's way into the parent side DNS servers. Because of the strong connection to the provisioned domain object and DNS servers both aspects should be visible in the RPP data model. Therefore the domain object is extended by an "dns" object having an array of DNS "records" and a facility for signaling parameters to "control" operational behavior. The top level format of a DNS resource record as described in section 3.2.1 of {{RFC1035}} is converted into properties. Property names MUST be written in camel case, generally using lower case letters, removing whitespaces and starting subsequent words with a capital letter.

~~~~ json
{
  "@type": "Domain",
  "name": "example.com",
  "dns": {
    "records": [
      {
        "name": "",
        "class": "",
        "type": "",
        "rdata": {}
      }
    ],
    "controls": {
      "ttl": {}
    }
  }
}
~~~~

### DNS record structure representation

#### name

The owner name of the DNS entry which MAY be the domain itself or a subordinate hostname. A server MUST NOT accept a NAME which is not a subordinate label to the provisioned domain name.

A server MUST accept values as "@", "relative names" and fully qualified domain names (FQDN).

"@" MUST be interpreted as the provisioned domain name.

"relative names" MUST be appended by the server with the provisioned domain name.

"FQDN" identified by a trailing dot (".") MUST NOT be interpreted by the server. A server MUST check if the provided name is a subordinate to the provisioned domain, or the domain itself.

Example:

~~~~ json
{
  "@type": "Domain",
  "name": "example.com",
  "dns": {
    "records": [
      {
        "name": "@",
        "type": "a",
        "rdata": {
          "address": "192.0.2.1"
        }
      },
      {
        "name": "www",
        "type": "a",
        "rdata": {
          "address": "192.0.2.2"
        }
      },
      {
        "name": "web.example.com.",
        "type": "a",
        "rdata": {
          "address": "192.0.2.3"
        }
      }
    ]
  }
}
~~~~

The above example implies three resulting records:

* An "A" RR for "example.com" ("@") set to 192.0.2.1.
* An "A" RR for "www.example.com" ("www" relative) set to 192.0.2.2.
* An "A" RR for "web.example.com" (FQDN) set to 192.0.2.3.

#### class

A client SHOULD omit the class. The server MUST assume "IN" as class of a transferred dataset and MAY decline other values. If present the value MUST be chosen from section 3.2.4. (CLASS values) of {{RFC1035}}.

#### type

The TYPE of data present in the RDATA. This also implies the expected fields in RDATA.
If present the value MUST chosen from section 3.2.2. (TYPE values) of {{RFC1035}} or other RFC describing the RR type. Values MUST be converted to lower case.

#### ttl

TTL is considered a operational control (see section 3.1.3 and section 4.3.1 of this document). A server MUST set a default value as TTL and MAY ignore other values send by a client.

#### rdlength

RDLENGTH specifies the length of the RDATA field and will be ignored in RPP. A client MUST NOT include this field. A server MUST ignore this field if present.

#### rdata

The RDATA structure depends on the TYPE and MUST be expressed as a JSON object. Property names MUST follow the definition of the RDATA described by the corresponding RFC. Property names MUST be written in camel case, generally using lower case letters, removing whitespaces and starting subsequent words with a capital letter.

Example:

* Section 3.3.11 (NS RDATA format) of {{RFC1035}} describes the RDATA of a NS RR having a field named "NSDNAME".
* Section 3.3.9 (MX RDATA format) of {{RFC1035}} describes the RDATA of a MX RR having the field named "PREFERENCE", "EXCHANGE".

The resulting structure is therefore:

~~~~ json
{
  "@type": "Domain",
  "name": "example.com",
  "dns": {
    "records": [
      {
        "name": "@",
        "type": "ns",
        "rdata": {
          "nsdname": "ns1.example.net."
        }
      },
      {
        "name": "@",
        "type": "mx",
        "rdata": {
          "preference": "10",
          "exchange": "mx1.example.net"
        }
      }
    ]
  }
}
~~~~

### Operational controls

In addition to the regular data a server MAY allow clients to control specific operational behavior. A client MAY extend the "dns" JSON object with a number of "controls".

~~~~ json
{
  "@type": "Domain",
  "name": "example.com",
  "dns": {
    "records": [
      {
        "name": "<name>",
        "type": "<type>",
        "rdata": {
          "rdataKey": "<rdataValue>"
        }
      }
    ],
    "controls": {
      "<namedControl>": "<namedControlValue>"
    }
  }
}
~~~~

### Future DNS record types

With respect to an evolving DNS landscape new record types - including delegation - may emerge. Usually these record type will be defined and standardized for the DNS in first. Adopting future record types MUST be done using the rules described in section 3.1.2.6 of this document.

# Use cases

## Domain delegation (Host Attribute)

To enable domain delegation a server MUST support the "NS", "A" and "AAAA" record types ({{RFC1035}}, {{RFC3596}}).

In this delegation model the delegation information and corresponding DNS configuration is attached directly to a domain object. This is corresponding to Host Attribute delegation model of {{RFC5731}}.

A minimal delegation can be expressed by adding an array of name servers to the DNS data of a domain:

~~~~ json
{
  "@type": "Domain",
  "name": "example.com",
  "dns": {
    "records": [
      {
        "name": "@",
        "type": "ns",
        "rdata": {
          "nsdname": "ns1.example.net."
        }
      },
      {
        "name": "@",
        "type": "ns",
        "rdata": {
          "nsdname": "ns2.example.net."
        }
      }
    ]
  }
}
~~~~

If GLUE records are needed the client may add records of type "A" or "AAAA" :

~~~~ json
{
  "@type": "Domain",
  "name": "example.com",
  "dns": {
    "records": [
      {
        "name": "@",
        "type": "ns",
        "rdata": {
          "nsdname": "ns1.example.net."
        }
      },
      {
        "name": "@",
        "type": "ns",
        "rdata": {
          "nsdname": "ns.example.com"
        }
      },
      {
        "name": "ns.example.com.",
        "type": "a",
        "rdata": {
          "address": "192.0.2.1"
        }
      },
      {
        "name": "ns.example.com.",
        "type": "aaaa",
        "rdata": {
          "address": "2001:DB8::1"
        }
      }
    ]
  }
}
~~~~

## Host Object

{{RFC5731}} specifies how domain delegation can be expressed as a relation to a separate provisioning object (Host Object), which carries the DNS configuration (name and glue records), with details specified in {{RFC5732}}.

To enable specification of Host Objexts, similar to direct domain delegation, a server MUST support the "NS", "A" and "AAAA" record types ({{RFC1035}}, {{RFC3596}}).

DNS configuration of Host Object is specified by NS, A and AAAA configuration within "dns" data structure:

~~~~ json
{
  "@type": "Host",
  "name": "ns.example.com",
  "dns": {
    "records": [
      {
        "name": "@",
        "type": "ns",
        "rdata": {
          "nsdname": "ns.example.com"
        }
      },
      {
        "name": "ns.example.com.",
        "type": "a",
        "rdata": {
          "address": "192.0.2.1"
        }
      },
      {
        "name": "ns.example.com.",
        "type": "aaaa",
        "rdata": {
          "address": "2001:DB8::1"
        }
      }
    ]
  }
}
~~~~

## DNSSEC

To enable DNSSEC provisioning a server SHOULD support either "DS" or "DNSKEY" or both record types. The records MUST be added to the "dns" array of the domain. If provided with only "DNSKEY" a server MUST calculate the DS record. If both record types are provided a server MAY use the DNSKEY to validate the DS record.

~~~~ json
{
  "@type": "Domain",
  "name": "example.com",
  "dns": {
    "records": [
      {
        "name": "@",
        "type": "ns",
        "rdata": {
          "nsdname": "ns1.example.net."
        }
      },
      {
        "name": "@",
        "type": "ns",
        "rdata": {
          "nsdname": "ns2.example.net."
        }
      },
      {
        "name": "@",
        "type": "ds",
        "rdata": {
          "keyTag": 12345,
          "algorithm": 13,
          "digestType": 2,
          "digest": "BE74359954660069D5C632B56F120EE9F3A86764247C"
        }
      }
    ]
  }
}
~~~~

~~~~ json
{
  "@type": "Domain",
  "name": "example.com.",
  "dns": {
    "records": [
      {
        "name": "@",
        "type": "ns",
        "rdata": {
          "nsdname": "ns1.example.net."
        }
      },
      {
        "name": "@",
        "type": "ns",
        "rdata": {
          "nsdname": "ns2.example.net."
        }
      },
      {
        "name": "@",
        "type": "dnskey",
        "rdata": {
          "flags": 257,
          "protocol": 3,
          "algorithm": 5,
          "publicKey": "AwEAAddt2AkL4RJ9Ao6LCWheg8"
        }
      }
    ]
  }
}
~~~~

## Operational controls

### TTL

The TTL controls the caching behavior of DNS resource records (see Section 5 of {{RFC9499}}). Typically a default TTL is defined by the registry operator. In some use cases it is desirable for a client to change the TTL value.

A client MAY assign "ttl" to the controls of an RR set which is intended to be present in the parent sides DNS. A server MAY ignore these values e.g. for policy reasons.

Example:

~~~~ json
{
  "@type": "Domain",
  "name": "example.com",
  "dns": {
    "records": [
      {
        "name": "@",
        "type": "a",
        "rdata": {
          "address": "192.0.2.1"
        }
      },
      {
        "name": "@",
        "type": "aaaa",
        "rdata": {
          "address": "2001:DB8::1"
        }
      }
    ],
    "controls": {
      "ttl": {
        "a": 86400,
        "aaaa": 3600
    }
    }
  }
}
~~~~

### Maximum signature lifetime

Maximum signature lifetime (maximumSignatureLifetime) describes the maximum number of seconds after signature generation a parents signature on signed DNS information should expire. The maximumSignatureLifetime value applies to the RRSIG resource record over the signed DNS RR. See Section 3 of {{RFC4034}} for information on the RRSIG resource record.

A client MAY assign "maximumSignatureLifetime" to the controls of an RR set which is intended to be signed on the parent side. A server MAY ignore these values, e.g. for policy reasons.

Example:

~~~~ json
{
  "@type": "Domain",
  "name": "example.com",
  "dns": {
    "records": [
      {
        "name": "@",
        "type": "ns",
        "rdata": {
          "nsdname": "ns1.example.net."
        }
      },
      {
        "name": "@",
        "type": "ns",
        "rdata": {
          "nsdname": "ns2.example.net."
        }
      },
      {
        "name": "@",
        "type": "ds",
        "rdata": {
          "keyTag": 12345,
          "algorithm": 13,
          "digestType": 2,
          "digest": "BE74359954660069D5C632B56F120EE9F3A86764247C"
        }
      }
    ],
    "controls": {
      "maximumSignatureLifetime": {
        "ds": 86400
      }
    }
  }
}
~~~~

## Authoritative DNS data

A server MAY support additional RR types, e.g. to support delegation-less provisioning. By doing this the registry operators name servers becomes authoritative for the registered domain. A server MUST consider resource records designed for delegation - including DNSSEC - and resource records representing authoritative data - except for GLUE RR - mutual exclusive.

~~~~ json
{
  "@type": "Domain",
  "name": "example.com",
  "dns": {
    "records": [
      {
        "name": "@",
        "type": "a",
        "rdata": {
          "address": "192.0.2.1"
        }
      },
      {
        "name": "www.example.com.",
        "type": "a",
        "rdata": {
          "address": "192.0.2.1"
        }
      },
      {
        "name": "@",
        "type": "aaaa",
        "rdata": {
          "address": "2001:DB8::1"
        }
      },
      {
        "name": "www.example.com.",
        "type": "a",
        "rdata": {
          "address": "2001:DB8::1"
        }
      },
      {
        "name": "@",
        "type": "mx",
        "rdata": {
          "preference": "10",
          "exchange": "mx1.example.com"
        }
      },
      {
        "name": "mx1.example.com.",
        "type": "a",
        "rdata": {
          "address": "192.0.2.2"
        }
      },
      {
        "name": "@",
        "type": "mx",
        "rdata": {
          "preference": "20",
          "exchange": "mx2.example.net"
        }
      },
      {
        "name": "@",
        "type": "txt",
        "rdata": {
          "txtData": "v=spf1 -all"
        }
      }
    ]
  }
}
~~~~

# Discoverability

The server MUST provide the following information per profile in the discovery document in section 10 of {{I-D.draft-ietf-rpp-requirements}}:

* A list of supported resource record types
* A list of applicable operational controls
* Minimum, maximum and default values for operational controls

TODO: Needs rewrite after definition of the discovery document

# EPP compatibility considerations

TODO

# Conventions and Definitions

{::boilerplate bcp14-tagged}


# Security Considerations

## Authoritative data

Allowing to store authoritative resource records (see section 4.4 of this document) in the registry provides faster resolution. However, if not done properly situations may occur where the data served authoritative should have been delegated. RPP servers MUST take precautions to not store authoritative and non-authoritative data at the same time.

The types and number of authoritative records can result in uncontrolled growth of the registries zone file and eventually exhaust the hardware resources of the registries name server. RPP servers SHOULD consider limiting the amount of authoritative records and carefully choose which record types are allowed.

## Host references within the rdata field

Some RR types (NS, MX and others) use references to host names which can be categorized into three categories:

Domain internal references
are references to a subordinate host name of the domain. E.g. "ns.example.com" is an domain internal reference when used as a name server for "example.com".

Registry internal references
are references to a host name within the same registry. E.g. "ns.example.com" is an domain internal reference when used as a name server for "example2.com".

Registry external references
are references to a host name outside of the registry. E.g. "ns.example.net" is an domain internal reference when used as a name server for "example.com".

Deletion of a host name while still being referenced may lead to severe security risks for the referencing domain.

# Change History

## -00 to -01

- Combined structure for resource record definition and operational controls (Section 3.1.1)
- Use camel case for property names instead of snake case


# IANA Considerations

This document has no IANA actions.

# Appendix A. Examples from current implementations

## EPP

### Create domain using host attributes example

EPP XML:

~~~~ xml
<?xml version="1.0" encoding="UTF-8"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0">
  <command>
    <create>
      <domain:create
          xmlns:domain="urn:ietf:params:xml:ns:domain-1.0">
        <domain:name>example.com</domain:name>
        <domain:period unit="y">1</domain:period>
        <domain:ns>
          <domain:hostAttr>
            <domain:hostName>ns1.example.com</domain:hostName>
            <domain:hostAddr ip="v4">192.0.2.1</domain:hostAddr>
            <domain:hostAddr ip="v6">2001:db8::1</domain:hostAddr>
          </domain:hostAttr>
          <domain:hostAttr>
            <domain:hostName>ns2.example.com</domain:hostName>
            <domain:hostAddr ip="v4">192.0.2.2</domain:hostAddr>
          </domain:hostAttr>
        </domain:ns>
        <domain:registrant>registrantID</domain:registrant>
        <domain:contact type="admin">adminID</domain:contact>
        <domain:contact type="tech">techID</domain:contact>
      </domain:create>
    </create>
    <extension>
      <secDNS:create
          xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1">
        <secDNS:maxSigLife>604800</secDNS:maxSigLife>
        <secDNS:dsData>
          <secDNS:keyTag>12345</secDNS:keyTag>
          <secDNS:alg>13</secDNS:alg>
          <secDNS:digestType>2</secDNS:digestType>
          <secDNS:digest>
            BE74359954660069D5C632B56F120EE9F3A86764247
          </secDNS:digest>
        </secDNS:dsData>
      </secDNS:create>
      <ttl:create xmlns:ttl="urn:ietf:params:xml:ns:epp:ttl-1.0">
        <ttl:ttl for="NS">3600</ttl:ttl>
      </ttl:create>
    </extension>
    <clTRID>clTRID-1234</clTRID>
  </command>
</epp>
~~~~

RPP JSON representation:

~~~~ json
{
  "@type": "Domain",
  "name": "example.com",
  "...": "",
  "dns": {
    "records": [
      {
        "name": "@",
        "type": "ns",
        "rdata": {
          "nsdname": "ns1.example.com"
        }
      },
      {
        "name": "ns1.example.com",
        "type": "a",
        "rdata": {
          "address": "192.0.2.1"
        }
      },
      {
        "name": "ns1.example.com",
        "type": "aaaa",
        "rdata": {
          "address": "2001:db8::1"
        }
      },
      {
        "name": "@",
        "type": "ns",
        "rdata": {
          "nsdname": "ns2.example.com"
        }
      },
      {
        "name": "ns2.example.com",
        "type": "a",
        "rdata": {
          "address": "192.0.2.2"
        }
      },
      {
        "name": "@",
        "type": "ds",
        "rdata": {
          "keyTag": 12345,
          "algorithm": 13,
          "digestType": 2,
          "digest": "BE74359954660069D5C632B56F120EE9F3A86764247"
        }
      }
    ],
    "controls": {
      "maximumSignatureLifetime": {
        "ds": 604800
      },
      "ttl": {
        "ns": 3600
      }
    }
  }
}
~~~~

### Create domain using host object example

EPP XML:

~~~~ xml
<?xml version="1.0" encoding="UTF-8"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0">
  <command>
    <create>
      <domain:create
          xmlns:domain="urn:ietf:params:xml:ns:domain-1.0">
        <domain:name>example.com</domain:name>
        <domain:period unit="y">1</domain:period>
        <domain:ns>
          <domain:hostObj>ns1.example.net</domain:hostObj>
          <domain:hostObj>ns2.example.net</domain:hostObj>
        </domain:ns>
        <domain:registrant>registrantID</domain:registrant>
        <domain:contact type="admin">adminID</domain:contact>
        <domain:contact type="tech">techID</domain:contact>
      </domain:create>
    </create>
    <extension>
      <secDNS:create
          xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1">
        <secDNS:maxSigLife>604800</secDNS:maxSigLife>
        <secDNS:dsData>
          <secDNS:keyTag>12345</secDNS:keyTag>
          <secDNS:alg>13</secDNS:alg>
          <secDNS:digestType>2</secDNS:digestType>
          <secDNS:digest>
            BE74359954660069D5C632B56F120EE9F3A86764247C
          </secDNS:digest>
        </secDNS:dsData>
      </secDNS:create>
      <ttl:create xmlns:ttl="urn:ietf:params:xml:ns:epp:ttl-1.0">
        <ttl:ttl for="NS">3600</ttl:ttl>
      </ttl:create>
    </extension>
    <clTRID>clTRID-1234</clTRID>
  </command>
</epp>
~~~~

RPP JSON representation:

~~~~ json
{
  "@type": "Domain",
  "name": "example.com",
  "...": "",
  "_object_references": {
    "nameserver": [
      {
        "name": "ns1.example.net.",
        "href": "https://rpp.example/nameservers/ns1.example.net",
        "rel": "nameserver"
      },
      {
        "name": "ns2.example.net.",
        "href": "https://rpp.example/nameservers/ns2.example.net",
        "rel": "nameserver"
      }
    ]
  },
  "dns": {
    "records": [
      {
        "name": "@",
        "type": "ds",
        "rdata": {
          "keyTag": 12345,
          "algorithm": 13,
          "digestType": 2,
          "digest": "BE74359954660069D5C632B56F120EE9F3A86764247C"
        }
      }
    ],
    "controls": {
      "maximumSignatureLifetime": {
        "ds": 604800
      },
      "ttl": {
        "ns": 3600
      }
    }
  }
}
~~~~

### Create host object example

EPP XML:

~~~~ xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0">
  <command>
    <create>
      <host:create
       xmlns:host="urn:ietf:params:xml:ns:host-1.0">
        <host:name>ns1.example.com</host:name>
        <host:addr ip="v4">192.0.2.2</host:addr>
        <host:addr ip="v4">192.0.2.29</host:addr>
        <host:addr ip="v6">1080:0:0:0:8:800:200C:417A</host:addr>
      </host:create>
    </create>
    <clTRID>ABC-12345</clTRID>
  </command>
</epp>
~~~~

RPP JSON representation:

~~~~ json
{
  "@type": "Host",
  "...": "",
  "name": "ns1.example.com",
  "dns": {
    "records": [
      {
        "name": "@",
        "type": "ns",
        "rdata": {
          "nsdname": "ns.example.com"
        }
      },
      {
          "name": "@",
          "type": "a",
          "rdata": {
              "address": "192.0.2.2"
          }
      },
      {
          "name": "@",
          "type": "a",
          "rdata": {
              "address": "192.0.2.29"
          }
      },
      {
          "name": "@",
          "type": "aaaa",
          "rdata": {
              "address": "1080:0:0:0:8:800:200C:417A"
          }
      }
    ]
  }
}
~~~~

## Free Registry for ENUM and Domains (FRED)

FRED is an open source registry software developed by CZ.NIC

### Create domain example

EPP XML:

~~~~ xml
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0">
  <command>
    <create>
      <domain:create
          xmlns:domain="http://www.nic.cz/xml/epp/domain-1.4">
        <domain:name>example.cz</domain:name>
        <domain:registrant>registrantID</domain:registrant>
        <domain:admin>adminID</domain:admin>
        <domain:nsset>nssetID</domain:nsset>
        <domain:keyset>keysetID</domain:keyset>
      </domain:create>
    </create>
    <clTRID>clTRID-1234</clTRID>
  </command>
</epp>
~~~~

### Create nsset example

EPP XML:

~~~~ xml
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0">
  <command>
    <create>
      <nsset:create
          xmlns:nsset="http://www.nic.cz/xml/epp/nsset-1.2">
        <nsset:id>nssetID</nsset:id>
        <nsset:ns>
          <nsset:name>ns1.example.cz</nsset:name>
          <nsset:addr>192.0.2.1</nsset:addr>
          <nsset:addr>192.0.2.2</nsset:addr>
        </nsset:ns>
        <nsset:ns>
          <nsset:name>nameserver-example.cz</nsset:name>
        </nsset:ns>
        <nsset:tech>techID</nsset:tech>
        <nsset:reportlevel>1</nsset:reportlevel>
      </nsset:create>
    </create>
    <clTRID>clTRID-1234</clTRID>
  </command>
</epp>
~~~~

### Create keyset example

EPP XML:

~~~~ xml
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0">
  <command>
    <create>
      <keyset:create
          xmlns:keyset="http://www.nic.cz/xml/epp/keyset-1.3">
        <keyset:id>keysetID</keyset:id>
        <keyset:dnskey>
          <keyset:flags>257</keyset:flags>
          <keyset:protocol>3</keyset:protocol>
          <keyset:alg>5</keyset:alg>
          <keyset:pubKey>AwEAAddt2AkL4RJ9Ao6LCWheg8</keyset:pubKey>
        </keyset:dnskey>
        <keyset:dnskey>
          <keyset:flags>257</keyset:flags>
          <keyset:protocol>3</keyset:protocol>
          <keyset:alg>5</keyset:alg>
          <keyset:pubKey>AwEAAddt2AkL4RJ9Ao6LCWheg9</keyset:pubKey>
        </keyset:dnskey>
        <keyset:tech>techID</keyset:tech>
      </keyset:create>
    </create>
    <clTRID>clTRID-1234</clTRID>
  </command>
</epp>
~~~~

RPP JSON representation:

TODO

~~~~ json
{}
~~~~


## Realtime Registry Interface (RRI)

RRI is a proprietary protocol developed by DENIC

### Create domain with name servers example

RRI XML:

~~~~ xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<registry-request
    xmlns="http://registry.denic.de/global/5.0"
    xmlns:domain="http://registry.denic.de/domain/5.0"
    xmlns:dnsentry="http://registry.denic.de/dnsentry/5.0">
  <domain:create>
    <domain:handle>example.de</domain:handle>
    <domain:contact role="holder">registrantID</domain:contact>
    <dnsentry:dnsentry xsi:type="dnsentry:NS">
      <dnsentry:owner>example.de</dnsentry:owner>
      <dnsentry:rdata>
        <dnsentry:nameserver>ns1.example.com</dnsentry:nameserver>
      </dnsentry:rdata>
    </dnsentry:dnsentry>
    <dnsentry:dnsentry xsi:type="dnsentry:NS">
      <dnsentry:owner>example.de</dnsentry:owner>
      <dnsentry:rdata>
        <dnsentry:nameserver>ns1.example.de</dnsentry:nameserver>
        <dnsentry:address>192.0.2.1</dnsentry:address>
      </dnsentry:rdata>
    </dnsentry:dnsentry>
    <dnsentry:dnsentry xsi:type="dnsentry:DNSKEY">
      <dnsentry:owner>example.de.</dnsentry:owner>
      <dnsentry:rdata>
        <dnsentry:flags>257</dnsentry:flags>
        <dnsentry:protocol>3</dnsentry:protocol>
        <dnsentry:algorithm>5</dnsentry:algorithm>
        <dnsentry:publicKey>
          AwEAAddt2AkL4RJ9Ao6LCWheg8
        </dnsentry:publicKey>
      </dnsentry:rdata>
    </dnsentry:dnsentry>
  </domain:create>
  <ctid>clTRID-1234</ctid>
</registry-request>
~~~~

RPP JSON representation:

~~~~ json
{
  "@type": "Domain",
  "name": "example.de",
  "...": "",
  "dns": {
    "records": [
      {
        "name": "@",
        "type": "ns",
        "rdata": {
          "nsdname": "ns1.example.com"
        }
      },
      {
        "name": "@",
        "type": "ns",
        "rdata": {
          "nsdname": "ns1.example.de"
        }
      },
      {
        "name": "ns1.example.de",
        "type": "a",
        "rdata": {
          "address": "192.0.2.1"
        }
      },
      {
        "name": "@",
        "type": "dnskey",
        "rdata": {
          "flags": 257,
          "protocol": 3,
          "algorithm": 5,
          "publicKey": "AwEAAddt2AkL4RJ9Ao6LCWheg8"
        }
      }
    ]
  }
}
~~~~

### Create domain without delegation example

RRI XML:

~~~~ xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<registry-request
    xmlns="http://registry.denic.de/global/5.0"
    xmlns:domain="http://registry.denic.de/domain/5.0"
    xmlns:dnsentry="http://registry.denic.de/dnsentry/5.0">
  <domain:update>
    <domain:handle>example.de</domain:handle>
    <domain:contact role="holder">registrantID</domain:contact>
    <dnsentry:dnsentry xsi:type="dnsentry:A">
      <dnsentry:owner>example.de</dnsentry:owner>
      <dnsentry:rdata>
        <dnsentry:address>192.0.2.1</dnsentry:address>
      </dnsentry:rdata>
    </dnsentry:dnsentry>
  </domain:update>
  <ctid>clTRID-1234</ctid>
</registry-request>
~~~~

RPP JSON representation:

~~~~ json
{
  "@type": "Domain",
  "name": "example.de",
  "...": "",
  "dns": {
    "records": [
      {
        "name": "@",
        "type": "a",
        "rdata": {
          "address": "192.0.2.1"
        }
      }
    ]
  }
}
~~~~

## RDAP

### Domain object

Registration Data Access Protocol (RDAP) is described in {{RFC9083}}. An extention proposing Time-to-Live (TTL) values is described in
{{I-D.draft-brown-rdap-ttl-extension}} and is close to adoption in the regext working group.

RDAP JSON:

~~~~ json
{
  "objectClassName": "domain",
  "ldhName": "example.com",
  "nameservers": [
    {
      "objectClassName": "nameserver",
      "ldhName": "ns1.example.com",
      "ipAddresses": {
        "v4": ["192.0.2.1"],
        "v6": ["2001:db8::1"]
      }
    },
    {
      "objectClassName": "nameserver",
      "ldhName": "ns2.example.com",
      "ipAddresses": {
        "v4": ["192.0.2.2"]
      }
    }
  ],
  "secureDNS": {
    "delegationSigned": true,
    "maxSigLife": 604800,
    "dsData": [
      {
        "keyTag": 12345,
        "algorithm": 13,
        "digestType": 2,
        "digest": "BE74359954660069D5C632B56F120EE9F3A86764247C"
      }
    ]
  },
  "ttl": [
       {
         "types": [ "NS" ],
         "value": 3600
       }
  ],
  "events": [
    {
      "eventAction": "registration",
      "eventDate": "2025-01-01T00:00:00Z"
    },
    {
      "eventAction": "expiration",
      "eventDate": "2035-01-01T00:00:00Z"
    }
  ],
  "status": ["active"]
}
~~~~

--- back

# Acknowledgments
{:numbered="false"}
