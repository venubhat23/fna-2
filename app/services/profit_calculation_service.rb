class ProfitCalculationService
  def self.calculate_profit_for_period(start_date, end_date)
    new.calculate_profit_for_period(start_date, end_date)
  end

  def self.calculate_profit_by_product(start_date, end_date)
    new.calculate_profit_by_product(start_date, end_date)
  end

  def self.calculate_profit_by_vendor(start_date, end_date)
    new.calculate_profit_by_vendor(start_date, end_date)
  end

  def calculate_profit_for_period(start_date, end_date)
    sale_items = SaleItem.joins(:order)
                         .where(orders: { created_at: start_date..end_date })
                         .includes(:product, :stock_batch, :order)

    total_revenue = sale_items.sum(:line_total)
    total_cost = sale_items.sum { |item| item.purchase_price * item.quantity }
    total_profit = sale_items.sum(:profit_amount)

    {
      period: "#{start_date.strftime('%d/%m/%Y')} - #{end_date.strftime('%d/%m/%Y')}",
      total_revenue: total_revenue.round(2),
      total_cost: total_cost.round(2),
      total_profit: total_profit.round(2),
      profit_margin: total_revenue > 0 ? (total_profit / total_revenue * 100).round(2) : 0,
      total_orders: sale_items.joins(:order).distinct.count('orders.id'),
      total_items_sold: sale_items.sum(:quantity)
    }
  end

  def calculate_profit_by_product(start_date, end_date)
    profits = SaleItem.joins(:order, :product)
                      .where(orders: { created_at: start_date..end_date })
                      .group('products.id', 'products.name')
                      .group('products.unit_type')
                      .select(
                        'products.id as product_id',
                        'products.name as product_name',
                        'products.unit_type',
                        'SUM(sale_items.quantity) as total_quantity_sold',
                        'SUM(sale_items.line_total) as total_revenue',
                        'SUM(sale_items.purchase_price * sale_items.quantity) as total_cost',
                        'SUM(sale_items.profit_amount) as total_profit',
                        'COUNT(DISTINCT orders.id) as order_count'
                      )

    profits.map do |profit_data|
      revenue = profit_data.total_revenue.to_f
      profit_margin = revenue > 0 ? (profit_data.total_profit.to_f / revenue * 100).round(2) : 0

      {
        product_id: profit_data.product_id,
        product_name: profit_data.product_name,
        unit_type: profit_data.unit_type || 'units',
        total_quantity_sold: profit_data.total_quantity_sold.to_f,
        total_revenue: revenue.round(2),
        total_cost: profit_data.total_cost.to_f.round(2),
        total_profit: profit_data.total_profit.to_f.round(2),
        profit_margin: profit_margin,
        order_count: profit_data.order_count,
        average_selling_price: profit_data.total_quantity_sold.to_f > 0 ? (revenue / profit_data.total_quantity_sold.to_f).round(2) : 0
      }
    end.sort_by { |item| -item[:total_profit] }
  end

  def calculate_profit_by_vendor(start_date, end_date)
    profits = SaleItem.joins(:order, stock_batch: :vendor)
                      .where(orders: { created_at: start_date..end_date })
                      .group('vendors.id', 'vendors.name')
                      .select(
                        'vendors.id as vendor_id',
                        'vendors.name as vendor_name',
                        'COUNT(DISTINCT products.id) as product_count',
                        'SUM(sale_items.quantity) as total_quantity_sold',
                        'SUM(sale_items.line_total) as total_revenue',
                        'SUM(sale_items.purchase_price * sale_items.quantity) as total_cost',
                        'SUM(sale_items.profit_amount) as total_profit',
                        'COUNT(DISTINCT orders.id) as order_count'
                      )
                      .joins(:product)

    profits.map do |profit_data|
      revenue = profit_data.total_revenue.to_f
      profit_margin = revenue > 0 ? (profit_data.total_profit.to_f / revenue * 100).round(2) : 0

      {
        vendor_id: profit_data.vendor_id,
        vendor_name: profit_data.vendor_name,
        product_count: profit_data.product_count,
        total_quantity_sold: profit_data.total_quantity_sold.to_f,
        total_revenue: revenue.round(2),
        total_cost: profit_data.total_cost.to_f.round(2),
        total_profit: profit_data.total_profit.to_f.round(2),
        profit_margin: profit_margin,
        order_count: profit_data.order_count
      }
    end.sort_by { |item| -item[:total_profit] }
  end

  def calculate_monthly_profit_trend(year = Date.current.year)
    monthly_data = []

    (1..12).each do |month|
      start_date = Date.new(year, month, 1)
      end_date = start_date.end_of_month

      month_profit = calculate_profit_for_period(start_date, end_date)

      monthly_data << {
        month: start_date.strftime('%B'),
        month_number: month,
        year: year,
        **month_profit
      }
    end

    {
      year: year,
      yearly_total: {
        revenue: monthly_data.sum { |m| m[:total_revenue] },
        cost: monthly_data.sum { |m| m[:total_cost] },
        profit: monthly_data.sum { |m| m[:total_profit] }
      },
      monthly_data: monthly_data
    }
  end

  def top_profitable_products(limit = 10, start_date = 1.month.ago, end_date = Date.current)
    calculate_profit_by_product(start_date, end_date).take(limit)
  end

  def top_profitable_vendors(limit = 10, start_date = 1.month.ago, end_date = Date.current)
    calculate_profit_by_vendor(start_date, end_date).take(limit)
  end

  def profit_summary_dashboard
    today = Date.current
    yesterday = 1.day.ago.to_date
    this_month_start = today.beginning_of_month
    last_month_start = 1.month.ago.beginning_of_month
    last_month_end = 1.month.ago.end_of_month

    {
      today: calculate_profit_for_period(today, today),
      yesterday: calculate_profit_for_period(yesterday, yesterday),
      this_month: calculate_profit_for_period(this_month_start, today),
      last_month: calculate_profit_for_period(last_month_start, last_month_end),
      top_products_this_month: top_profitable_products(5, this_month_start, today),
      top_vendors_this_month: top_profitable_vendors(5, this_month_start, today)
    }
  end

  def vendor_wise_product_profit(vendor_id, start_date, end_date)
    SaleItem.joins(:order, :product, stock_batch: :vendor)
            .where(vendors: { id: vendor_id })
            .where(orders: { created_at: start_date..end_date })
            .group('products.id', 'products.name', 'products.unit_type')
            .select(
              'products.id as product_id',
              'products.name as product_name',
              'products.unit_type',
              'SUM(sale_items.quantity) as total_quantity_sold',
              'SUM(sale_items.line_total) as total_revenue',
              'SUM(sale_items.purchase_price * sale_items.quantity) as total_cost',
              'SUM(sale_items.profit_amount) as total_profit',
              'AVG(sale_items.selling_price) as average_selling_price',
              'AVG(sale_items.purchase_price) as average_purchase_price'
            )
            .map do |data|
      revenue = data.total_revenue.to_f
      profit_margin = revenue > 0 ? (data.total_profit.to_f / revenue * 100).round(2) : 0

      {
        product_id: data.product_id,
        product_name: data.product_name,
        unit_type: data.unit_type || 'units',
        total_quantity_sold: data.total_quantity_sold.to_f,
        total_revenue: revenue.round(2),
        total_cost: data.total_cost.to_f.round(2),
        total_profit: data.total_profit.to_f.round(2),
        profit_margin: profit_margin,
        average_selling_price: data.average_selling_price.to_f.round(2),
        average_purchase_price: data.average_purchase_price.to_f.round(2)
      }
    end
  end
end