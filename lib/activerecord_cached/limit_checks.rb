module ActiveRecordCached
  private

  def check_limit(relation, method, result)
    values = Array(result)
    if values.count == max_count
      warn_limit_reached("#{relation.klass}.#{method} >= #{max_count} max_count")
    elsif max_bytes_exceeded?(values)
      warn_limit_reached("#{relation.klass}.#{method} >= #{max_bytes} max_bytes")
    end
  end

  def warn_max_total_bytes_exceeded(store_size = nil)
    warn_limit_reached("Store size >= #{store_size || max_total_bytes} max_total_bytes")
  end

  def warn_limit_reached(info)
    on_limit_reached.call("ActiveRecordCached: data getting too big to cache. #{info}")
  end

  def max_bytes_exceeded?(values)
    memsize = 0
    max_bytes && values.inject(0) do |value|
      memsize += Marshal.dump(value).bytesize
      return true if memsize >= max_bytes
    end
    false
  end
end
