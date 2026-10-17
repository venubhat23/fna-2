# Runs several COUNT queries in a single round trip to the database.
#
#   BatchCount.call(total: Coupon.all, active: Coupon.active, expired: Coupon.expired)
#   # => { total: 12, active: 7, expired: 3 }
#
# Each relation becomes a scalar subquery, so the result for each key is exactly
# what `relation.count` would return (distinct / joins / limit are all respected).
# Ordering, includes and preload are dropped since they never affect a count.
# Pass plain scopes - not ones that rely on includes/references for their WHERE.
class BatchCount
  def self.call(**relations)
    return {} if relations.empty?

    connection = relations.values.first.klass.connection
    selects = relations.map do |key, relation|
      pk = relation.klass.arel_table[relation.klass.primary_key]
      inner = relation.except(:order, :includes, :preload, :select).select(pk).to_sql
      alias_name = connection.quote_column_name(key.to_s)
      "(SELECT COUNT(*) FROM (#{inner}) AS batch_count_sub) AS #{alias_name}"
    end

    row = connection.select_one("SELECT #{selects.join(', ')}")
    relations.keys.index_with { |key| row[key.to_s].to_i }
  end
end
