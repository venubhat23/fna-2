# Invalidate the admin subscriptions list cache on any write to the tables it reads.
# See lib/admin_subscriptions_cache.rb.
ActiveSupport::Notifications.subscribe('sql.active_record') do |_name, _start, _finish, _id, payload|
  next if payload[:name] == 'SCHEMA' || payload[:cached]

  AdminSubscriptionsCache.bump! if AdminSubscriptionsCache.write_sql?(payload[:sql])
end
