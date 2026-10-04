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

  # Customer sidebar badge counts, fetched in a single
  # round trip and memoized for the request (the support page reuses
  # :open_requests). Values are always fresh — only the query count changes.
  def customer_sidebar_counts
    @customer_sidebar_counts ||= begin
      customer = current_customer
      if customer
        BatchCount.call(
          active_orders: customer.bookings.where(status: %w[confirmed processing packed shipped out_for_delivery]),
          unpaid_invoices: customer.bookings.where.not(invoice_number: [nil, '']).where(payment_status: [:unpaid, nil]),
          active_subscriptions: customer.milk_subscriptions.where(is_active: true),
          pending_referrals: customer.referrals.pending,
          open_requests: customer.client_requests.where(status: %w[pending in_progress])
        )
      else
        Hash.new(0)
      end
    end
  end
end
