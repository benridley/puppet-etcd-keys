require 'etcd'
require 'puppet_x/etcd/etcd_config'

class Puppet::Provider::EtcdKey::EtcdKey
  def initialize
    config = PuppetX::Etcd::EtcdConfig.new
    Puppet.debug("Loaded etcd config: #{config.config_hash}")
    @client = Etcd.client(config.config_hash)
    Puppet.debug("Successfully connected to Etcd")
  end

  def get(context, names = nil)
    if names
      names.each do |name|
        response = @client.get(name, recursive: true)
        create_puppet_resources(response.node)
      end
    else
      response = @client.get('/', recursive: true)
      create_puppet_resources(response.node)
    end
  end

  def set(context, changes)
    changes.each do |name, change| 
      should = change[:should]
      if should[:ensure] == 'present' && should[:is_directory]
        context.error('Cannot have value when directory attribute is true.') if should[:value]
        @client.set(name, dir: true)
      elsif should[:ensure] == 'present' && should[:value]
        @client.set(name, value: should[:value])
      elsif should[:ensure] == 'absent'
        @client.delete(name, recursive: true)
      end
    end
  end

  # Recursively applies attributes required by Puppet (ensure, value, etc) to a result from the etcd client.
  def create_puppet_resources(etcd_node)
    nodes = []
    node = {
      path: etcd_node.key || '/',
      ensure: 'present',
    }
    if etcd_node.dir
      node[:directory] = true
      nodes << node
      nodes += etcd_node.children.map { |child_node| create_puppet_resources(child_node) }.flatten
      nodes
    elsif etcd_node.value
      node[:directory] = false
      node[:value] = etcd_node.value
      nodes << node
    end
  end
end
