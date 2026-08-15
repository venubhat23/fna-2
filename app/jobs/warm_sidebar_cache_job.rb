class WarmSidebarCacheJob < ApplicationJob
  queue_as :default

  # layouts/_sidebar.html.erb renders on every admin page, so a cold miss on
  # this badge count is a tax paid app-wide, not just on one page. TTL
  # (5 min) is kept longer than this job's schedule (1 min) so a request
  # never lands in the gap right after expiry but before the next warm run.
  def perform
    Rails.cache.fetch('admin_sidebar_invoice_check_pending_count', expires_in: 5.minutes) do
      MilkSubscription.joins(:customer).where(is_active: true).select(:customer_id).distinct.count
    end
  end
end
