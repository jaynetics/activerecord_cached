module ActiveRecordCached
  class Railtie < ::Rails::Railtie
    config.to_prepare do
      ActiveRecordCached.clear_all
    end
  end
end
