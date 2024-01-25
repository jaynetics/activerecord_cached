module ActiveRecordCached
  class RedisMutex
    KEY = 'ActiveRecordCached:RedisMutex'
    MAX_HOLD_TIME = 2
    LOCK_ACQUIRER = "return redis.call('setnx', KEYS[1], 1) == 1 and redis.call('expire', KEYS[1], KEYS[2]) and 1 or 0"

    def initialize(redis)
      @redis = redis.then(&:itself)
    end

    def synchronize(&block)
      acquire_lock
      begin
        block.call
      ensure
        release_lock
      end
    end

    private

    def acquire_lock
      sleep_t = 0.005
      while @redis.eval(LOCK_ACQUIRER, [KEY, MAX_HOLD_TIME]) != 1 do sleep(sleep_t *= 1.6) end
    end

    def release_lock
      @redis.del(KEY)
    end
  end
end
