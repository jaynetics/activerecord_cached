# frozen_string_literal: true

require "active_record"
require "active_support"

require_relative "activerecord_cached/activerecord_extensions"
require_relative "activerecord_cached/cache"
require_relative "activerecord_cached/configuration"
require_relative "activerecord_cached/limit_checks"
require_relative "activerecord_cached/railtie" if defined?(::Rails::Railtie)
require_relative "activerecord_cached/redis_mutex"
require_relative "activerecord_cached/version"

module ActiveRecordCached
  extend self
end
