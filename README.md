# etcd-keys

A Puppet module for interacting with etcd keys. 

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with etcd](#setup)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Limitations - OS compatibility, etc.](#limitations)
5. [Development - Guide for contributing to the module](#development)

## Description

This module contains utilites for working with etcd with Puppet. Its main features are:
* An etcd_key Puppet resource. This allows you to manage your etcd keys declaratively over the etcd API. Currently only a v2 provider is implemented. The connection is managed with a config file. 
* An etcd_key hiera lookup. This allows you to retrieve arbitrary keys from your etcd instance. 


## Setup

This module requires the 'etcd' gem installed on your Puppet master (or agent if that's where you're going to run it.) This gem has minimal dependencies and is well tested.

Once you've installed the gem, you'll need to configure config file. By default, the module will look for 'etcd.conf' in your Puppet config directory. You can use ```puppet config print confdir``` on your master to locate this directory.

The config file is in YAML format and supports the following options: 
  *host - Required field. Where your etcd is located (ip address/hostname)
  *port - Required field. 
  *use_ssl - Optional - Whether to use ssl for etcd server authentication
  *ca_file - Optional - Location of the CA used to authenticate the TLS connection. 
  *ssl_cert - Optional - Certificate location for TLS client authentication. 
  *ssl_key  - Optional - Private key location for TLS client authentication.

Example config file:
``` yaml
# /etc/puppetlabs/puppet/etcd.conf
---
host: 127.0.01
port: 2379
use_ssl: true
ca_file: /etc/pki/tls/certs/ca.pem

```

### Usage

# Using the etcd_key Resource
The module provides a resource called 'etcd_key' that allows you to declare etcd keys. 

``` ruby
  etcd_key { '/my/key': 
    ensure => present,
    value  => 'I am a key!',
  }

  etcd_key { '/no/key': 
    ensure => absent,
  }
```

You can also declare directories:

``` ruby
  etcd_key { '/container/for/keys': 
    ensure => directory,
  }
```

# Using the hiera lookup function
The module also provides a hiera backend for searching etcd keys. 
Add the function to your hiera.yaml file:

``` yaml
# hiera.yaml

hierarchy:
  - name: "etcd backend"
    lookup_key: hiera_etcd
    options:
      # Optional path to a config file. Default is etcd.conf in your puppet dir.
      config_path: '/etc/etcd_lookup/lookup.conf'
```

You can now use ```lookup('/path/to/your/key')``` to lookup etcd keys in your manifests. Another useful option is using the hiera ```alias``` function to define parameters for classes based on etcd. An example: 
``` yaml
# data/my_hiera_file.yaml

my_module::my_paramater: "%{alias('/etcd/key')}"
```

## Reference

See REFERENCE.md for more details.

## Limitations

The module only works with the v2 API currently. As of current writing, etcd will support v2 and v3 APIs out of the box at the same time (although they are isolated from one another). The v3 API uses gRPC instead of HTTP/REST, so will require a new provider to be implemented. I may do this in future. 

## Development

All pull requests welcome. 