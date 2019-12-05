require 'etcd'
require 'puppet_x/etcd/etcd_config'

Puppet::Type.type(:etcd_key).provide(:etcd_v2_api) do
  desc "Provides etcd_key management using the etcd v2 api. Requires the 'etcd' gem to operate."
  def initialize(value = {})
    super(value)
    config = PuppetX::Etcd::EtcdConfig.new
    Puppet.debug("Loaded etcd config: #{config.config_hash}")
    @client = Etcd.client(config.config_hash)
    Puppet.debug("Successfully connected to Etcd")
  end

  def create
    raise ArgumentError, "value and directory are mutually exclusive" if resource[:value] && resource[:ensure] == :directory

    if resource[:ensure] == :directory
      @client.set(resource[:path], dir: true)
    elsif resource[:ensure] == :present
      @client.set(resource[:path], value: resource[:value])
    end
  end

  def destroy
    @client.delete(resource[:path], recursive: true)
  end

  def exists?
    @client.exists?(resource[:path])
  end

  def ensure
    if @client.exists?(resource[:path])
      response = @client.get(resource[:path])
      return :directory if response.node.dir

      return :present
    end
    :absent
  end

  def ensure=(_)
    create unless resource[:ensure] == :absent
    destroy
  end

  def value
    @client.get(resource[:path]).value
  end

  def value=(_)
    @client.set(resource[:path], value: resource[:value])
  end
end
