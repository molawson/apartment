class ActiveRecord::ConnectionAdapters::ConnectionHandler
  def retrieve_connection_pool_with_tenant(klass)
    klass = Apartment::ConnectionPool.new.class_for_model(klass)
    retrieve_connection_pool_without_tenant(klass)
  end

  alias_method_chain :retrieve_connection_pool, :tenant

  def pool_exists?(name)
    class_to_pool.keys.include? name
  end
end
