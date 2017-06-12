module ActiveRecord
  module ConnectionHandling
    # Taken from the following and modified as commented below:
    # https://github.com/rails/rails/blob/v5.0.0.1/activerecord/lib/active_record/connection_handling.rb#L47-L57
    def establish_connection(spec = nil)
      raise RuntimeError, "Anonymous class is not allowed." unless name

      spec     ||= DEFAULT_ENV.call.to_sym
      resolver =   ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new configurations

      # If we pass in a spec, send the tenant (set in Apartment::AbstractAdapter)
      # as the connection name. If spec is not a hash revert to existing behavior.
      spec_name = if spec.is_a?(Hash)
                    spec.fetch(:tenant, fallback_connection_specification_name)
                  else
                    fallback_connection_specification_name
                  end

      spec = resolver.spec(spec, spec_name)

      unless respond_to?(spec.adapter_method)
        raise AdapterNotFound, "database configuration specifies nonexistent #{spec.config[:adapter]} adapter"
      end

      remove_connection(spec.name)
      self.connection_specification_name = spec.name
      connection_handler.establish_connection spec
    end

    def fallback_connection_specification_name
      self == Base ? 'primary' : name
    end
  end
end
