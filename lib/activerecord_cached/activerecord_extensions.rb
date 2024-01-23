# define cached_* methods, e.g. cached_pluck
module ActiveRecordCached
  module BaseExtension
    def clear_cached_values
      ActiveRecordCached.clear_for_model(self)
    end
  end

  module RelationExtension
    def clear_cached_values
      ActiveRecordCached.clear_for_model(klass)
    end
  end

  %i[count maximum minimum pick pluck records sum].each do |method|
    BaseExtension.class_eval <<~RUBY, __FILE__, __LINE__ + 1
      def cached_#{method}(*args)
        all.cached_#{method}(*args)
      end
    RUBY

    RelationExtension.class_eval <<~RUBY, __FILE__, __LINE__ + 1
      def cached_#{method}(*args)
        ActiveRecordCached.fetch(self, :#{method}, args)
      end
    RUBY
  end

  ActiveRecord::Base.singleton_class.prepend BaseExtension
  ActiveRecord::Relation.prepend RelationExtension

  # bust cache on individual record changes - this module is included
  # automatically into models that use cached methods.
  module CRUDCallbacks
    def self.included(base)
      base.after_commit { self.class.clear_cached_values }
    end
  end

  # bust cache on mass operations
  module MassOperationWrapper
    %i[delete_all insert_all touch_all update_all update_counters upsert_all].each do |mass_op|
      class_eval <<~RUBY, __FILE__, __LINE__ + 1
        def #{mass_op}(...)
          result = super(...)
          result && clear_cached_values
          result
        end
      RUBY
    end
  end
  ActiveRecord::Base.singleton_class.prepend MassOperationWrapper
  ActiveRecord::Relation.prepend MassOperationWrapper
end
