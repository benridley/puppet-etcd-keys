require 'yaml'
require 'etcd'

# Provides a utility class for loading and validating etcd config
class EtcdConfig
  VALID = ['host', 'port', 'use_ssl', 'ca_file', 'user_name', 'password', 'restrict_paths'].freeze
  REQUIRED = ['host', 'port'].freeze

  attr_reader :config_hash

  def process_config_file(file_path)
    etcd_config = YAML.load_file(file_path)
    etcd_config.each { |field, _| raise EtcdConfigError, "Invalid config option #{field}." unless VALID.include?(field) }
    REQUIRED.each { |field| raise EtcdConfigError "Missing required field #{field} in #{file_path}" unless etcd_config.key?(field)}
    @config_hash = etcd_config.map { |k, v| [k.to_sym, v] }.to_h
    Puppet.debug("Successfully parsed config file with host #{@config_hash[:host]} port #{@config_hash[:port]}")
  end

  def default_config_file
    Puppet.initialize_settings unless Puppet[:confdir]
    File.join(Puppet[:confdir], 'etcd.conf')
  end

  def initialize(config_path = nil)
    process_config_file(config_path || default_config_file)
  end
end

class EtcdConfigError < StandardError
end

Puppet::Functions.create_function(:hiera_etcd) do
  dispatch :hiera_backend do
    param 'Variant[String, Numeric]', :key
    param 'Hash', :options
    param 'Puppet::LookupContext', :context
  end

  def hiera_backend(key, options, context)
    return context.not_found unless key.match(%r{(\/\w+)+})

    client = get_etcd_client(options, context)
    return context.not_found unless client.exists?(key)

    client.get(key).value
  end

  def get_etcd_client(options, context)
    return context.cached_value('client') if context.cache_has_key('client')

    # Check for config_path override in the Hiera config, otherwise use the default etcd.conf in Puppet dir
    config = if options.key?('config_path')
               EtcdConfig.new(options['config_path'])
             else
               EtcdConfig.new
             end
    client = Etcd.client(config.config_hash)
    context.cache('client', client)
    client
  end
end
