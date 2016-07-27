require 'apartment/adapters/abstract_adapter'

module Apartment

  module Tenant

    def self.sqlserver_adapter(config)
      config['default_schema'] = 'dbo' if config['default_schema'].eql?('public')
      Adapters::SqlserverAdapter.new config
    end
  end

  module Adapters

    class SqlserverAdapter < AbstractAdapter

      protected

      #   Connect to new database
      #   Abstract adapter will catch generic ActiveRecord error
      #   Catch specific adapter errors here
      #
      #   @param {String} database Database name
      #
      def connect_to_new(tenant)
        Apartment::ConnectionPool.new.use multi_tenantify(tenant)
      rescue TinyTds::Error => exception
        Apartment::Tenant.reset unless tenant == default_tenant
        raise_connect_error!(tenant, exception)
      end
    end
  end
end
