module SidebarHelper
  # Badge counters rendered on almost every admin page. They already went
  # through Rails.cache with a few minutes' TTL, but Rails.cache here is
  # Solid Cache backed by the same cross-region Postgres as the primary DB
  # (see lib/local_ttl_cache.rb) — so every page render still paid a full
  # network round trip per badge, cache hit or not. This adds an in-process
  # layer in front so most renders cost nothing.
  SIDEBAR_LOCAL_CACHE = LocalTtlCache.new
  SIDEBAR_BADGE_LOCAL_TTL = 30.seconds

  def sidebar_badge_count(key)
    SIDEBAR_LOCAL_CACHE.fetch(key, SIDEBAR_BADGE_LOCAL_TTL) { yield }
  rescue StandardError
    0
  end
end
