# Runs several scalar COUNT / SUM queries in a single round trip to the database.
#
#   BatchAggregate.call(
#     orders:  [Order.all, :count],
#     revenue: [Booking.where(created_at: range), :sum, :total_amount],
#     stock:   [Product.all, :sum, 'price * stock']
#   )
#   # => { orders: 12, revenue: 0.45e4, stock: 0.1e5 }
#
# Each value matches what the plain `relation.count` / `relation.sum(...)` call
# returns: counts are Integers, a sum over a column is cast with that column's
# type (0 over no rows, e.g. 0.0 for a decimal), and an expression sum is a
# BigDecimal, or Integer 0 over no rows.
# Like BatchCount, pass plain scopes - not ones that rely on includes/references.
class BatchAggregate
  def self.call(**specs)
    return {} if specs.empty?

    connection = specs.values.first.first.klass.connection
    selects = specs.map do |key, (relation, op, expr)|
      base = relation.except(:order, :includes, :preload, :select)
      inner = case op
              when :count
                pk = relation.klass.arel_table[relation.klass.primary_key]
                "SELECT COUNT(*) FROM (#{base.select(pk).to_sql}) AS batch_aggregate_sub"
              when :sum
                column = expr.is_a?(Symbol) ? relation.klass.arel_table[expr] : Arel.sql(expr.to_s)
                base.select(column.sum).to_sql
              else
                raise ArgumentError, "unsupported aggregate #{op.inspect}"
              end
      "(#{inner}) AS #{connection.quote_column_name(key.to_s)}"
    end

    row = connection.select_one("SELECT #{selects.join(', ')}")
    specs.to_h do |key, (relation, op, expr)|
      raw = row[key.to_s]
      value = if op == :count
                raw.to_i
              elsif expr.is_a?(Symbol)
                relation.klass.type_for_attribute(expr.to_s).deserialize(raw || 0)
              elsif raw.nil?
                0
              else
                raw.is_a?(Numeric) ? raw : BigDecimal(raw.to_s)
              end
      [key, value]
    end
  end
end
