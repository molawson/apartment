module Apartment
  module Extensions
    module ActiveRecord
      module ConnectionHandling
        THREAD_LOCAL_NAME = :active_record_connection_specification_name

        def connection_specification_name
          Thread.current[THREAD_LOCAL_NAME] || super
        end

        def connection_specification_name=(new_name)
          Thread.current[THREAD_LOCAL_NAME] = new_name
          super if Thread.current == Thread.main
        end
      end
    end
  end
end
