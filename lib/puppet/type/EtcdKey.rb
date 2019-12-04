require 'puppet/resource_api'
require 'etcd'

Puppet::ResourceApi.register_type(
  name: 'EtcdKey',
  docs: 'This type allows the management of etcd keys as Puppet resources.',
  attributes: {
    ensure: {
      type: 'Enum[present, absent]',
      desc: 'Whether the key should be present in the etcd structure. Use ensure => key to ensure a value, or ensure => directory for an empty directory key.',
      default: 'present',
    },
    path: {
      type: 'String',
      desc: 'The path of the key you want to manage in the etcd structure.',
      behaviour: :namevar,
    },
    value: {
      type: 'String',
      desc: 'The value of the key. Only applicable with ensure=key.',
    },
    dir: {
      type: 'Boolean',
      desc: 'Whether this key is a directory or not.',
    },
  }
)
