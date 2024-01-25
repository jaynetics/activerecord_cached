ActiveSupport::Cache.format_version = 7.1

RSpec.configuration.around(:each, :redis) do |example|
  old_store = ActiveRecordCached.cache_store
  redis_store = ActiveSupport::Cache::RedisCacheStore.new(
    error_handler: ->*{ raise },
    url: 'redis://localhost:6379/7',
  )
  redis_store.write('foo', 'bar') rescue skip('skipping b/c redis is not running')
  ActiveRecordCached.cache_store = redis_store
  example.run
ensure
  ActiveRecordCached.cache_store = old_store
end
