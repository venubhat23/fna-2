class OrderFulfillmentService
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :order, :inventory_service, :errors

  def initialize(order, inventory_service = InventoryService.new)
    @order = order
    @inventory_service = inventory_service
    @errors = []
  end

  def self.fulfill_order(order)
    service = new(order)
    service.fulfill
  end

  def self.can_fulfill_order?(order)
    service = new(order)
    service.can_fulfill?
  end

  def fulfill
    return false unless can_fulfill?

    begin
      ActiveRecord::Base.transaction do
        # Get order items from order_items or booking_items (depending on your structure)
        order_items = get_order_items

        all_allocations = []

        # Check and allocate stock for each item
        order_items.each do |item|
          allocations = inventory_service.allocate_stock(item.product_id, item.quantity)
          all_allocations.concat(allocations)
        end

        # Reduce stock from allocated batches
        inventory_service.reduce_stock(all_allocations)

        # Create sale items for profit tracking
        sale_items = create_sale_items_from_allocations(all_allocations)

        # Update order status if needed
        update_order_after_fulfillment

        true
      end
    rescue InventoryService::InsufficientStockError, InventoryService::AllocationError => e
      @errors << e.message
      Rails.logger.error "Order fulfillment failed for order #{order.id}: #{e.message}"
      false
    rescue StandardError => e
      @errors << "Unexpected error during fulfillment: #{e.message}"
      Rails.logger.error "Unexpected error during order fulfillment for order #{order.id}: #{e.message}"
      false
    end
  end

  def can_fulfill?
    order_items = get_order_items
    @errors.clear

    order_items.each do |item|
      availability = inventory_service.check_availability(item.product_id, item.quantity)

      unless availability[:available]
        @errors << "Product '#{item.product.name}' - Available: #{availability[:available_stock]}, Required: #{availability[:requested_quantity]}, Shortage: #{availability[:shortage]}"
      end
    end

    @errors.empty?
  end

  def fulfillment_preview
    order_items = get_order_items
    items_for_simulation = order_items.map do |item|
      {
        product_id: item.product_id,
        quantity: item.quantity
      }
    end

    simulation = inventory_service.simulate_allocation(items_for_simulation)

    {
      can_fulfill_all: simulation.all? { |sim| sim[:can_fulfill] },
      total_items: simulation.count,
      fulfilled_items: simulation.count { |sim| sim[:can_fulfill] },
      simulation_details: simulation
    }
  end

  def get_profit_calculation
    preview = fulfillment_preview

    return { total_profit: 0, items: [] } unless preview[:can_fulfill_all]

    total_profit = 0
    profit_items = []

    preview[:simulation_details].each do |sim|
      item_profit = 0

      sim[:allocation_details].each do |alloc|
        allocation_profit = (alloc[:selling_price] - alloc[:purchase_price]) * alloc[:allocated_quantity]
        item_profit += allocation_profit
      end

      total_profit += item_profit
      profit_items << {
        product_name: sim[:product_name],
        quantity: sim[:requested_quantity],
        profit: item_profit
      }
    end

    {
      total_profit: total_profit.round(2),
      items: profit_items
    }
  end

  private

  def get_order_items
    if order.order_items.exists?
      order.order_items.includes(:product)
    elsif order.booking&.booking_items&.exists?
      order.booking.booking_items.includes(:product)
    else
      []
    end
  end

  def create_sale_items_from_allocations(allocations)
    sale_items = []

    # Group allocations by product for easier processing
    allocations.group_by { |alloc| alloc[:batch].product }.each do |product, product_allocations|
      product_allocations.each do |allocation|
        sale_item = SaleItem.create!(
          order: order,
          product: product,
          stock_batch: allocation[:batch],
          quantity: allocation[:quantity],
          selling_price: allocation[:selling_price],
          purchase_price: allocation[:purchase_price]
        )
        sale_items << sale_item
      end
    end

    sale_items
  end

  def update_order_after_fulfillment
    # Update order status to reflect that it's been fulfilled
    case order.status
    when 'draft'
      order.update!(status: 'confirmed')
    when 'ordered_and_delivery_pending'
      order.update!(status: 'confirmed')
    end
  end
end