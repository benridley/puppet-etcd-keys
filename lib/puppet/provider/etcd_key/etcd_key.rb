require 'etcd'
require 'puppet_x/etcd/etcd_config'

class Puppet::Provider::Etcd_Key::Etcd_Key
  def initialize
    config = Puppet_X::Etcd::EtcdConfig.new
    @client = Etcd.client(config)
  end

  def get(context, names = nil)
    if names
      names.each do |name|
        response = @client.get(name, recursive: true)
        create_puppet_resources(response.node)
      end
    else
      response = @client.get('/', recursive: true)
      apply_puppet_attributes(response.node)
    end
  end

  def set(context, changes)
    changes.each do |name, change| 
      should = change[:should]
      if should[:ensure] == 'dir'
        context.error('Cannot have value when directory attribute is true.') if should[:value] 
        client.set(name, directory: true)
      elsif should[:ensure] == 'key'
        client.set(name, value: should[:value])
      elsif should[:ensure] == 'absent'
        client.delete(name, recursive: true)
      end
    end
  end

  # Recursively applies attributes required by Puppet (ensure, value, etc) to a result from the etcd client.
  def create_puppet_resources(etcd_node)
    nodes = []
    node = {
      path: etcd_node.key || '/',
    }
    if etcd_node.dir
      node[:ensure] = 'dir'
      nodes << node
      nodes += etcd_node.children.map { |child_node| create_puppet_resources(child_node) }
      nodes
    elsif etcd_node.value
      node[:ensure] = 'key'
      node[:value] = etcd_node.value
      nodes << node
    end
  end
end
