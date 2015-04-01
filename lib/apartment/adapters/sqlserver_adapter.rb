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

      def connect_to_new(tenant)
        super
      rescue TinyTds::Error
        Apartment::Tenant.reset unless tenant == default_tenant
        raise DatabaseNotFound, "Cannot find database #{environmentify(database)}"
      end
    end
  end
end
