[![Gem Version](https://badge.fury.io/rb/activerecord_cached.svg)](http://badge.fury.io/rb/activerecord_cached)
[![Build Status](https://github.com/jaynetics/activerecord_cached/actions/workflows/main.yml/badge.svg)](https://github.com/jaynetics/activerecord_cached/actions)

# ActiveRecordCached

This gem adds methods to cache small amounts of ActiveRecord data in RAM, Redis, or other stores.

The cache for each model is busted both by individual CRUD operations on that model (e.g. `#update`), as well as by mass operations (e.g. `#update_all`).

The cached methods work on whole models as well as on relations.

There is an automatic warning if the data is getting too big to cache.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add activerecord_cached

## Usage

```ruby
Pizza.cached_count # => 2374
Pizza.limit(2).cached_pluck(:name) # => ["Funghi", "Spinaci"]
Pizza.select(:id, :name).cached_records # => [#<Pizza id=1 name="Funghi">, ...]
```

Configuration:

```ruby
ActiveRecordCached.configure do |config|
  # How to cache the data. Default: MemoryStore
  config.cache_store = Rails.cache

  # Maximum size of the standard memory store. Default: 32MB
  config.max_total_bytes = 16.megabytes

  # How much data to allow per cached relation. Default: 1MB
  config.max_bytes = 2.megabytes

  # How many records to allow per cached relation. Default: 10k
  config.max_count = 1000

  # What do to when any limit is exceeded. Default: warn
  config.on_limit_reached = ->msg{ report(msg) }
end
```

Specs:

```ruby
RSpec.configure do |config|
  config.after(:each) { ActiveRecordCached.clear_all }
end
```

## Tradeoffs

The default MemoryStore is orders of magnitude faster than e.g. Redis, but it is wiped when the app is deployed or otherwise restarted, which may present a [cache stampede](https://en.wikipedia.org/wiki/Cache_stampede) risk under very high load.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jaynetics/activerecord_cached.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
