# frozen_string_literal: true

require "activerecord_cached"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: 'test.db')

ActiveRecord::Base.connection.execute <<~SQL
  CREATE TABLE IF NOT EXISTS pizzas  (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT);
SQL
ActiveRecord::Base.connection.execute <<~SQL
  CREATE TABLE IF NOT EXISTS curries (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT);
SQL

class Pizza < ActiveRecord::Base; end
class Curry < ActiveRecord::Base; end

def clear_tables
  ActiveRecord::Base.connection.execute 'DELETE FROM pizzas;'
  ActiveRecord::Base.connection.execute 'DELETE FROM curries;'
end

RSpec.configure do |config|
  config.after(:each) do
    clear_tables
    ActiveRecordCached.clear_all
  end
end
