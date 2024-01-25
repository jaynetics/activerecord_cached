# frozen_string_literal: true

require "activerecord_cached"
Dir[File.join(__dir__, 'support', '**', '*.rb')].each { |f| require f }

RSpec.configuration.after(:each) { ActiveRecordCached.clear_all }
