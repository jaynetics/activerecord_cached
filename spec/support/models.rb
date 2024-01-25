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

RSpec.configuration.after(:each) { clear_tables }
