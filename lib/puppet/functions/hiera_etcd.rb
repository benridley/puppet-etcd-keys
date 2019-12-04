require 'yaml'

Puppet::Functions.create_function(:hiera_http) do
  begin
    require 'etcd'
  rescue LoadError => e
    raise Puppet::DataBinding::LookupError, "Must install etcd gem to use hiera-http"
  end
end