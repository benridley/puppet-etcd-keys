require 'puppet/resource_api'
require 'etcd'

Puppet::ResourceApi.register_type(
  name: 'etcd_key',
  docs: 'This type allows the management of etcd keys as Puppet resources.',
  attributes: {
    ensure: {
      type: 'Enum[present, absent]',
      desc: 'Whether the key should be present in the etcd structure.',
      default: 'present',
    },
    path: {
      type: 'String',
      desc: 'The path of the key you want to manage in the etcd structure.',
      behaviour: :namevar,
    },
    directory: {
      type: 'Boolean',
      desc: 'Whether this key is a directory or not.',
      default: false,
    },
    value: {
      type: 'String',
      desc: 'The value of the key. Mutually exclusive if with is_directory => true.',
    },
  },
)
