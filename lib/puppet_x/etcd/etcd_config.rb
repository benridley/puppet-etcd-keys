# frozen_string_literal: true

module PuppetX
  module Etcd
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
  end
end
