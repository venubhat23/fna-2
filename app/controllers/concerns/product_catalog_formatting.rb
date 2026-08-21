module ProductCatalogFormatting
  extend ActiveSupport::Concern

  private

  # format_product_data reads category, approved_reviews (average_rating/total_reviews) and
  # stock (in_stock?/low_stock?/stock_status) per product. None of those respect a plain
  # includes(:stock_batches) since they're aggregate queries, so this preloads the associations
  # that ARE respected and pins the stock figure to the cached_stock column via the same
  # SQL-aggregate pattern used in admin/bookings_controller.rb#new.
  def preload_product_listing(relation)
    relation
      .select("products.*, COALESCE(SUM(stock_batches.quantity_remaining), 0) AS cached_stock")
      .includes(:category, :approved_reviews, :product_variants, image_attachment: :blob, additional_images_attachments: :blob)
  end

  def format_product_data(product)
    {
      id: product.id,
      name: product.name,
      description: product.description,
      price: product.price.to_f,
      discount_price: product.discount_price&.to_f,
      selling_price: product.selling_price.to_f,
      final_price: product.final_price_after_discount.to_f,
      discount_percentage: product.discount_percentage,
      discount_type: product.discount_type,
      discount_value: product.discount_value&.to_f,
      original_price: product.original_price&.to_f,
      savings_amount: product.savings_amount.to_f,
      stock: product.stock,
      sku: product.sku,
      unit: product.unit_type,
      weight: product.weight&.to_f,
      dimensions: product.dimensions,
      product_type: product.product_type,
      barcode: product.respond_to?(:barcode) ? product.barcode : nil,
      hsn_code: product.hsn_code,
      tags: product.tags,
      display_order: product.display_order,
      is_subscription_enabled: product.is_subscription_enabled,
      is_occasional_product: product.is_occasional_product,
      gst_enabled: product.gst_enabled,
      gst_percentage: product.gst_percentage&.to_f,
      category: {
        id: product.category_id,
        name: product.category&.name
      },
      image: product.images_attached? ? url_for(product.images.first) : nil,
      images: product.images_attached? ? product.images.map { |img| url_for(img) } : [],
      rating: {
        average: product.average_rating.to_f,
        count: product.total_reviews
      },
      is_in_stock: product.in_stock?,
      is_discounted: product.discounted?,
      is_low_stock: product.low_stock?,
      stock_status: product.stock_status,
      has_multiple_quantities: product.has_multiple_quantities?,
      display_price: product.display_price.to_f,
      default_variant_id: product.has_multiple_quantities? ? product.default_variant&.id : nil,
      variants: product.has_multiple_quantities? ? product.sorted_variants.map { |v|
        {
          id: v.id,
          label: v.label,
          weight: v.weight.to_f,
          unit: v.unit,
          buying_price: v.buying_price&.to_f,
          selling_price: v.selling_price.to_f,
          discount_enabled: v.discount_enabled,
          discount_type: v.discount_type,
          discount_value: v.discount_value&.to_f,
          discount_amount: v.discount_amount&.to_f,
          effective_price: v.effective_price.to_f,
          gst_percentage: v.gst_percentage&.to_f,
          gst_amount: v.gst_amount&.to_f,
          price_with_gst: v.price_with_gst.to_f,
          available_stock: v.available_stock.to_f,
          is_default: v.is_default,
          is_in_stock: v.available_stock > 0
        }
      } : [],
      created_at: product.created_at,
      updated_at: product.updated_at
    }
  end
end
