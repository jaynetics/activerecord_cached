module ActiveRecordCached
  def configure(&block)
    tap(&block)
  end

  def cache_store
    @cache_store ||= store_with_limit_warning(
      ActiveSupport::Cache::MemoryStore.new({ coder: nil, size: max_total_bytes })
    )
  end

  def cache_store=(val)
    val.is_a?(ActiveSupport::Cache::Store) || raise(ArgumentError, 'pass an ActiveSupport::Cache::Store')
    @cache_store = store_with_limit_warning(val)
  end

  mattr_accessor(:max_total_bytes) { 32.megabytes }
  def max_total_bytes=(val)
    val.is_a?(Integer) && val > 0 || raise(ArgumentError, 'pass an int > 0')
    super
  end

  mattr_accessor(:max_count) { 10_000 }
  def max_count=(val)
    val.is_a?(Integer) && val > 0 || val.nil? || raise(ArgumentError, 'pass an int > 0 or nil')
    super
  end

  mattr_accessor(:max_bytes) { 1.megabyte }
  def max_bytes=(val)
    val.is_a?(Integer) && val > 0 || val.nil? || raise(ArgumentError, 'pass an int > 0 or nil')
    super
  end

  mattr_accessor(:on_limit_reached) { ->(msg) { warn(msg) } }
  def on_limit_reached=(val)
    val.is_a?(Proc) && val.arity == 1 || raise(ArgumentError, 'pass a proc with arity 1')
    super
  end

  private

  def store_with_limit_warning(store)
    return store unless store.is_a?(ActiveSupport::Cache::MemoryStore)

    store.singleton_class.prepend(Module.new do
      def prune(...)
        ActiveRecordCached.send(:warn_max_total_bytes_exceeded)
        super
      end
    end)
    store
  end
end
