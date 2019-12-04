# frozen_string_literal: true

module Puppet_X::Etcd
  # Provides a utility class for loading and validating etcd config
  class EtcdConfig
    VALID = {
      fields: [:host, :port, :use_ssl, :ca_file, :user_name, :password, :restrict_paths],
    }.freeze
    REQUIRED = {
      fields: [:host, :port],
    }.freeze

    attr_reader :host, :port, :use_ssl, :ca_file, :user_name, :password, :restrict_paths

    def process_config_file(file_path)
      etcd_config = YAML.load_file(file_path)
      etcd_config.assert_valid_keys(VALID[:fields])
      etcd_config.each { |k, v| instance_variable_set("@#{k}".to_sym, v) }
      REQUIRED.each { |field| raise "Missing required field #{field} in #{file_path}" unless instance_variable_defined?(field) }
    end

    def default_config_file
      Puppet.initialize_settings unless Puppet[:confdir]
      File.join(Puppet[:confdir], 'etcd.conf')
    end

    def initialize
      process_config_file(default_config_file)
    end
  end
end
