require 'etcd'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'etcd', 'etcd_config.rb'))

Puppet::Type.type(:etcd_key).provide(:etcd_v2_api) do
  desc "Provides etcd_key management using the etcd v2 api. Requires the 'etcd' gem to operate."
  def initialize(value = {})
    super(value)
    config = PuppetX::Etcd::EtcdConfig.new
    Puppet.debug("Loaded etcd config: #{config.config_hash}")
    @client = Etcd.client(config.config_hash)
    Puppet.debug('Successfully connected to Etcd')
  end

  def create
    send('value=')
  end

  def destroy
    @client.delete(resource[:path], recursive: true)
  end

  def exists?
    @client.exists?(resource[:path])
  end

  def ensure
    validate_input
    if @client.exists?(resource[:path])
      response = @client.get(resource[:path])
      return :directory if response.node.dir

      return :present
    end
    :absent
  end

  def ensure=(_)
    send('value=') unless resource[:ensure] == :absent
    destroy
  end

  def value
    # If value is a hash, we need to compare recursively.
    if resource[:value].is_a?(Hash)
      response = @client.get(resource[:path], recursive: true)
      return format_nodes(response.node)
    end
    @client.get(resource[:path]).value
  end

  def value=(should = resource[:value])
    # If changing the value of a key recursively, remove everything underneath to ensure a clean write.
    if resource[:ensure] == :directory
      @client.delete(resource[:path], recursive: true) if exists?
      if should.empty?
        @client.set(resource[:path], dir: true)
      else
        write_hash(resource[:path], should)
      end
    else
      # Delete directory if trying to set it to a value
      Puppet.debug("Removing directory to set value: #{resource[:path]}")
      @client.delete(resource[:path], recursive: true) if exists? && @client.get(resource[:path]).node.dir
      @client.set(resource[:path], should)
    end
  end

  # Write hash allows writing recursively to etcd (i.e. passing a Hash as a value)
  def write_hash(path, value)
    if value.is_a?(Hash)
      value.each { |k, v| write_hash("#{path}/#{k}", v) }
    else
      @client.set(path, value: value)
    end
  end

  def validate_input
    raise ArgumentError, 'Cannot ensure hash as key value. Use ensure => directory to ensure a hash value recursively' if resource[:ensure] == :present && resource[:value].is_a?(Hash)
    raise ArgumentError, 'Cannot assign value to directory unless value is a hash' if resource[:ensure] == :directory && (!resource[:value].nil? && !resource[:value].is_a?(Hash))
    raise ArgumentError, 'Cannot assign nil value to key' if resource[:ensure] == :present && resource[:value].nil?
    raise ArgumentError, 'Cannot assign value to absent key' if resource[:ensure] == :absent && !resource[:value].nil?
  end

  def format_nodes(node)
    if node.dir && node.children
      return node.children.each_with_object({}) { |child, hash| hash[File.basename(child.key)] = format_nodes(child) }
    end
    return nil if node.dir && !node.children

    node.value
  end
end
