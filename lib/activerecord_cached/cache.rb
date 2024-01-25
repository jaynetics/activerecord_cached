module ActiveRecordCached
  def fetch(relation, method, args)
    key = ['ActiveRecordCached', relation.to_sql, method, args.sort].join(':')
    cache_store.fetch(key, expires_in: 1.day + rand(300).seconds, race_condition_ttl: 10.seconds) do
      # The gem keeps track of all cache keys used for each model for easy clearing.
      # Using #delete_matched would be too slow on large redis instances.
      log_model_cache_key(relation.klass, key)
      query_db(relation, method, args)
    end
  end

  def clear_for_model(model)
    synchronize do
      hash = fetch_cache_keys_per_model
      return unless model_keys = hash.delete(model)&.keys

      # delete from the key list first so that if a fetch comes in right after,
      # it can write the key to the list again
      write_cache_keys_per_model(hash)
      cache_store.delete_multi(model_keys)
    end
  end

  def clear_all
    synchronize do
      all_keys = fetch_cache_keys_per_model.values.flat_map(&:keys)
      write_cache_keys_per_model({})
      cache_store.delete_multi(all_keys)
    end
  end

  private

  def log_model_cache_key(model, key)
    synchronize do
      hash = fetch_cache_keys_per_model
      (hash[model] ||= {})[key] = true
      write_cache_keys_per_model(hash)
    end
  end

  def synchronize(&block)
    cache_store_semaphore.synchronize(&block)
  end

  require 'monitor'
  MONITOR = Monitor.new

  def cache_store_semaphore
    case cache_store
    when ActiveSupport::Cache::MemoryStore then MONITOR
    when ActiveSupport::Cache::RedisCacheStore then RedisMutex.new(cache_store.redis)
    end
  end

  def fetch_cache_keys_per_model
    cache_store.read(CACHE_KEYS_KEY) || {}
  end

  def write_cache_keys_per_model(val)
    cache_store.write(CACHE_KEYS_KEY, val)
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
