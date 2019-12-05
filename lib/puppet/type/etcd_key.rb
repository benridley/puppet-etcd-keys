require 'etcd'
require 'puppet_x/etcd/etcd_config'

Puppet::Type.newtype(:etcd_key) do
  @doc = %q{Creates a key in a remote etcd database. Connection options for etcd are specified in the
    etcd.conf file located in your puppet confdir (Use puppet config print --confdir on your master to find this.)

    Example:
    etcd_key { '/test/key':
      ensure => present,
      value  => 'Test value!',
    }
  }

  def pre_run_check
    # Check we can parse config and connect to etcd
    config = PuppetX::Etcd::EtcdConfig.new
    Puppet.debug("Loaded etcd config: #{config.config_hash}")
    client = Etcd.client(config.config_hash)
    begin
      client.leader
    rescue StandardError => e
      raise Puppet::Error, "Failed pre-run etcd connection validation: #{e.message}."
    end
  end

  newproperty(:ensure) do
    desc "Whether the key should exist in etcd or not. You can use ensure => directory to ensure an empty diectory."
    newvalue(:present) { provider.create }
    newvalue(:directory) { provider.create }
    newvalue(:absent) { provider.destroy }
    defaultto :present
  end

  newparam(:path) do
    desc "The path of the key in the etcd structure."

    validate do |value|
      raise ArgumentError "Invalid etcd path #{value}" unless value.match(%r{(\/\w+)+})
    end
    isnamevar
  end

  newproperty(:value) do
    desc "The value of the key. Mutually exclusive with directory => true."
  end
end
