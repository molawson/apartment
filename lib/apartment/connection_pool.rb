module Apartment
  class ConnectionPool

    extend Forwardable

    def_delegators :connection_handler, :pool_exists?, :remove_connection

    def tenant
      Apartment::Database.current_database
    end

    def use(spec)
      klass = class_for_database(spec[:database])
      if pool_exists?(klass.name)
        klass.connection
      else
        establish_connection(klass, spec)
      end
      klass.connection.enable_query_cache!
    end

    def class_for_model(klass)
      if use_default_pool?(klass)
        klass
      else
        database = Apartment::Database.current_database
        class_for_database(database)
      end
    end

    def clear_query_cache(database)
      klass = class_for_database database
      klass.connection.clear_query_cache
    end

    private

    def connection_handler
      ActiveRecord::Base.connection_handler
    end

    def class_for_database(database)
      klass_name = database.underscore.classify
      find_or_create_dummy_class(klass_name)
    end

    def find_or_create_dummy_class(klass_name)
      Apartment.const_get(klass_name)
    rescue NameError
      new_class = Class.new(ActiveRecord::Base)
      Apartment.const_set(klass_name, new_class)
    end

    def establish_connection(klass, spec)
      klass.establish_connection(spec).connection
    rescue => error
      remove_connection(klass) if pool_exists?(klass.name)
      raise error
    end

    def use_default_pool?(klass)
      klass == ActiveRecord::Base ||
        Apartment.use_schemas ||
        Apartment.excluded_models.include?(klass.name)
    end
  end
end
