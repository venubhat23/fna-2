# In-process cache for the admin subscriptions list page
# (Admin::SubscriptionsController#index). Every query from that page is a round
# trip to the cross-region Postgres (see lib/local_ttl_cache.rb), so a repeat view
# of the same filter/page is served from memory instead.
#
# Invalidation: VERSION is part of every cache key and is bumped by the
# sql.active_record subscriber in config/initializers/admin_subscriptions_cache.rb
# on any INSERT/UPDATE/DELETE against the tables the page reads - including
# update_all/insert_all/delete_all, which skip model callbacks. Writes made by
# another process (a separate job worker, a rails runner script) aren't seen
# here, so TTL is the upper bound on staleness for those.
module AdminSubscriptionsCache
  TTL = 30.seconds
  TABLES = %w[milk_subscriptions milk_delivery_tasks customers delivery_people products].freeze
  WRITE_SQL = /\A\s*(?:INSERT\s+INTO|UPDATE|DELETE\s+FROM)\s+"?(?:#{TABLES.join('|')})"?\b/i

  VERSION = Concurrent::AtomicFixnum.new
  STORE = LocalTtlCache.new

  def self.fetch(*key_parts, &block)
    STORE.fetch(['admin_subscriptions_index', VERSION.value, *key_parts].join('|'), TTL, &block)
  end

  def self.bump!
    VERSION.increment
  end

  def self.write_sql?(sql)
    WRITE_SQL.match?(sql)
  end
end
