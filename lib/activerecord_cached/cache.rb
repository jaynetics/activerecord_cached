module ActiveRecordCached
  def fetch(relation, method, args)
    key = ['ActiveRecordCached', relation.to_sql, method, args.sort].join(':')
    model = relation.klass
    prepare(model)
    cache_store.fetch(key) do
      log_model_cache_key(model, key)
      query_db(relation, method, args)
    end
  end

  def clear_for_model(model)
    keys = cache_keys_per_model
    return unless model_keys = keys.delete(model)&.keys

    cache_store.delete_multi(model_keys)
    cache_store.write(CACHE_KEYS_KEY, keys)
  end

  def clear_all
    all_keys = cache_keys_per_model.values.flat_map(&:keys)
    cache_store.delete_multi(all_keys)
    cache_store.delete(CACHE_KEYS_KEY)
  end

  private

  def prepare(model)
    return if CRUDCallbacks.in?(model.included_modules)

    PREPARE_MUTEX.synchronize do
      CRUDCallbacks.in?(model.included_modules) || model.include(CRUDCallbacks)
    end
  end

  PREPARE_MUTEX = Mutex.new

  def log_model_cache_key(model, key)
    keys = cache_keys_per_model
    (keys[model] ||= {})[key] = true
    cache_store.write(CACHE_KEYS_KEY, keys)
  end

  def cache_keys_per_model
    cache_store.read(CACHE_KEYS_KEY) || {}
  end

  CACHE_KEYS_KEY = 'ActiveRecordCached:cache_keys_per_model'

  def query_db(rel, method, args)
    rel = rel.limit(max_count) if max_count && rel.limit_value.nil?
    result = rel.send(method, *args)
    result = result.to_a if method == :select
    check_limit(rel, method, result)
    result
  end
end
