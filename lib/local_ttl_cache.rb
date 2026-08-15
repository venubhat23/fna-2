# In-process (per-worker), short-TTL cache for values that would otherwise
# be read through Rails.cache on every call. In this app Rails.cache is
# Solid Cache, backed by the same cross-region Postgres as the primary DB
# (config/database.yml `cache:` uses the same remote host as `primary:`) —
# so a Rails.cache "hit" still pays a full network round trip, same as an
# uncached query would. A hit here is a plain Ruby hash read with no network
# hop at all.
#
# Not a replacement for Rails.cache: it's a thin, short-TTL layer in front
# of it (or in front of a raw query) for values read far more often than
# they change, where callers already tolerate at least this much staleness
# (every call site using this class documents its own tolerance). Because
# state lives per-worker-process, a value written on one worker is only
# picked up by other workers once their own copy expires.
class LocalTtlCache
  def initialize
    @store = {}
    @mutex = Mutex.new
  end

  def fetch(key, ttl)
    now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    entry = @store[key]
    return entry[:value] if entry && entry[:expires_at] > now

    @mutex.synchronize do
      entry = @store[key]
      return entry[:value] if entry && entry[:expires_at] > now
      value = yield
      @store[key] = { value: value, expires_at: now + ttl }
      value
    end
  end

  def write(key, value, ttl)
    now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    @mutex.synchronize { @store[key] = { value: value, expires_at: now + ttl } }
  end

  def delete(key)
    @mutex.synchronize { @store.delete(key) }
  end
end
