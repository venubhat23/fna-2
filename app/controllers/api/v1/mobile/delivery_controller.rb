module Api
  module V1
    module Mobile
      class DeliveryController < ApplicationController
        include ProductCatalogFormatting

        before_action :authenticate_delivery_person!

        # A task counts as delivered once it is marked delivered/completed (same as admin delivery sales).
        DELIVERED_STATUSES = %w[delivered completed].freeze

        # GET /api/v1/mobile/delivery/tasks/today
        def tasks_today
          begin
            tasks = get_todays_tasks
            formatted_tasks = format_tasks(tasks)

            render json: {
              success: true,
              data: {
                summary: task_summary(tasks),
                tasks: formatted_tasks,
                route_optimization: route_optimization(tasks, formatted_tasks)
              }
            }
          rescue => e
            render json: { success: false, message: e.message }, status: :internal_server_error
          end
        end

        # GET /api/v1/mobile/delivery/tasks/:id
        def task_details
          begin
            task = find_task(params[:id])

            if task
              render json: {
                success: true,
                data: { task: format_task_details(task) }
              }
            else
              render json: { success: false, message: "Task not found" }, status: :not_found
            end
          rescue => e
            render json: { success: false, message: e.message }, status: :internal_server_error
          end
        end

        # POST /api/v1/mobile/delivery/tasks/:id/start
        def start_task
          begin
            task = find_task(params[:id])

            if task.nil?
              render json: { success: false, message: "Task not found" }, status: :not_found
              return
            end

            # Update task status to in_progress
            if update_task_status(task, 'in_progress')
              render json: {
                success: true,
                message: "Delivery started",
                data: {
                  task_id: task.id,
                  status: "in_progress",
                  started_at: Time.current,
                  estimated_arrival: estimate_arrival_time
                }
              }
            else
              render json: { success: false, message: "Failed to start delivery" }, status: :unprocessable_entity
            end
          rescue => e
            render json: { success: false, message: e.message }, status: :internal_server_error
          end
        end

        # POST /api/v1/mobile/delivery/tasks/:id/complete
        def complete_task
          begin
            task = find_task(params[:id])

            if task.nil?
              render json: { success: false, message: "Task not found" }, status: :not_found
              return
            end

            # Complete the delivery
            if complete_delivery(task, params)
              render json: {
                success: true,
                message: "Delivery completed successfully",
                data: {
                  task_id: task.id,
                  status: "completed",
                  completed_at: Time.current,
                  payment_status: "collected",
                  next_task_id: get_next_task_id
                }
              }
            else
              render json: { success: false, message: "Failed to complete delivery" }, status: :unprocessable_entity
            end
          rescue => e
            render json: { success: false, message: e.message }, status: :internal_server_error
          end
        end

        # POST /api/v1/mobile/delivery/tasks/:id/update_location
        def update_location
          begin
            task = find_task(params[:id])

            if task.nil?
              render json: { success: false, message: "Task not found" }, status: :not_found
              return
            end

            # Update delivery person location
            if update_delivery_location(params[:latitude], params[:longitude])
              distance = calculate_distance_to_customer(task, params[:latitude], params[:longitude])

              render json: {
                success: true,
                message: "Location updated",
                data: {
                  distance_to_customer: "#{distance} meters",
                  estimated_arrival: "#{(distance / 100).round} minutes"
                }
              }
            else
              render json: { success: false, message: "Failed to update location" }, status: :unprocessable_entity
            end
          rescue => e
            render json: { success: false, message: e.message }, status: :internal_server_error
          end
        end

        # POST /api/v1/mobile/delivery/bulk_mark_done
        def bulk_mark_done
          begin
            # Validate request parameters
            if params[:delivery_ids].blank? || !params[:delivery_ids].is_a?(Array)
              render json: { success: false, message: "No delivery IDs provided" }, status: :bad_request
              return
            end

            delivery_ids = params[:delivery_ids].map(&:to_i).uniq
            delivery_person_id = params[:delivery_person_id] || current_delivery_person_id
            completed_at = params[:completed_at] || Time.current

            # Process bulk updates
            result = process_bulk_delivery_update(delivery_ids, delivery_person_id, completed_at)

            if result[:updated_count] > 0
              render json: {
                success: true,
                message: "#{result[:updated_count]} of #{delivery_ids.count} deliveries marked as done",
                data: result
              }
            else
              render json: {
                success: false,
                message: "Failed to update deliveries",
                data: result
              }, status: :unprocessable_entity
            end
          rescue => e
            Rails.logger.error "Bulk delivery update error: #{e.message}"
            render json: {
              success: false,
              message: "Internal server error while processing bulk update",
              error: Rails.env.development? ? e.message : nil
            }, status: :internal_server_error
          end
        end

        # POST /api/v1/mobile/delivery/tasks/bulk_action
        # { "operation": "complete" | "delete", "task_ids": [94355, 12] }
        # Checkbox actions on the tasks/today list. Each id is looked up as a subscription delivery
        # task first, then as a booking (order). Only the caller's own tasks are touched.
        # "delete" cancels the task (kept for history/invoices) and it drops out of tasks/today.
        # Tasks the customer paused are hidden from tasks/today too.
        def bulk_task_action
          operation = params[:operation].to_s
          unless %w[complete delete].include?(operation)
            return render json: { success: false, message: "operation must be 'complete' or 'delete'" }, status: :unprocessable_entity
          end

          task_ids = params[:task_ids]
          if task_ids.blank? || !task_ids.is_a?(Array)
            return render json: { success: false, message: "task_ids (array of task ids) is required" }, status: :bad_request
          end

          requested = task_ids.map(&:to_i).select(&:positive?).uniq
          subscription_tasks = MilkDeliveryTask.where(id: requested, delivery_person_id: current_delivery_person_id).index_by(&:id)
          bookings = Booking.where(id: requested - subscription_tasks.keys, delivery_person_id: current_delivery_person_id).index_by(&:id)

          updated = []
          failed = []
          now = Time.current

          requested.each do |id|
            record = subscription_tasks[id] || bookings[id]
            unless record
              failed << { id: id, error: "Task not found" }
              next
            end

            type = record.is_a?(Booking) ? 'order' : 'subscription'
            if (error = apply_task_operation(record, operation, now))
              failed << { id: id, type: type, error: error }
            else
              updated << { id: id, type: type, status: record.is_a?(Booking) ? map_booking_status(record.status) : record.status }
            end
          rescue => e
            failed << { id: id, error: e.message }
          end

          verb = operation == 'complete' ? 'completed' : 'deleted'
          render json: {
            success: updated.any?,
            message: "#{updated.size} of #{requested.size} tasks #{verb}",
            data: { operation: operation, updated_count: updated.size, failed_count: failed.size, updated: updated, failed: failed }
          }, status: updated.any? ? :ok : :unprocessable_entity
        rescue => e
          render json: { success: false, message: e.message }, status: :internal_server_error
        end

        # GET /api/v1/mobile/delivery/my_customers?month=YYYY-MM|all
        # Mirrors /admin/customer_orders: customers are grouped by the delivery person on their
        # (non-cancelled) subscriptions running in the month, ordered by row_number.
        def my_customers
          month_start = parse_customer_month(params[:month])
          me = current_delivery_person_id

          if month_start
            month_end = month_start.end_of_month
            candidate_ids = MilkSubscription.where(delivery_person_id: me)
                                            .where.not(status: 'cancelled')
                                            .for_date_range(month_start, month_end)
                                            .distinct.pluck(:customer_id)
            month_subs = MilkSubscription.where(customer_id: candidate_ids)
                                         .where.not(status: 'cancelled')
                                         .for_date_range(month_start, month_end)
                                         .to_a.group_by(&:customer_id)
            customer_ids = month_subs.select { |_, subs| subscription_delivery_person_id(subs) == me }.keys
          else
            candidate_ids = MilkSubscription.where(delivery_person_id: me).distinct.pluck(:customer_id)
            all_subs = MilkSubscription.where(customer_id: candidate_ids).to_a.group_by(&:customer_id)
            customer_ids = all_subs.select { |_, subs| subscription_delivery_person_id(subs) == me }.keys
          end

          customers = Customer.where(id: customer_ids)
                              .with_attached_profile_image
                              .with_attached_personal_image
                              .with_attached_house_image
                              .order(:row_number, :first_name, :last_name).to_a

          render json: {
            success: true,
            data: {
              month: month_start ? month_start.strftime('%Y-%m') : 'all',
              month_label: month_start&.strftime('%B %Y'),
              customers: customers.each_with_index.map { |c, i| format_customer(c).merge(serial: i + 1) },
              total: customers.size
            }
          }
        rescue => e
          render json: { success: false, message: e.message }, status: :internal_server_error
        end

        # GET /api/v1/mobile/delivery/summary?date=YYYY-MM-DD
        # Liters delivered by the logged-in delivery person for the day, its week (Mon-Sun)
        # and its month, plus a day-by-day breakdown of the month.
        # Same rules as /admin/delivery_sales: only delivered/completed tasks, ml converted to liters.
        def summary
          date = parse_summary_date(params[:date])
          week_start = date.beginning_of_week(:monday)
          week_end = week_start + 6
          month_start = date.beginning_of_month
          month_end = date.end_of_month

          rows = MilkDeliveryTask
            .where(delivery_person_id: current_delivery_person_id,
                   status: DELIVERED_STATUSES,
                   delivery_date: [month_start, week_start].min..[month_end, week_end].max)
            .group(:delivery_date, :unit)
            .pluck(:delivery_date, :unit, Arel.sql('SUM(quantity)'), Arel.sql('COUNT(*)'))

          daily = Hash.new { |h, k| h[k] = { liters: 0.0, deliveries: 0 } }
          rows.each do |day, unit, qty, count|
            daily[day][:liters] += quantity_in_liters(qty, unit)
            daily[day][:deliveries] += count
          end

          sum_for = lambda do |range|
            cells = daily.select { |day, _| range.cover?(day) }.values
            { liters: cells.sum { |c| c[:liters] }.round(2), deliveries: cells.sum { |c| c[:deliveries] } }
          end

          render json: {
            success: true,
            data: {
              date: date.iso8601,
              day: sum_for.call(date..date),
              week: sum_for.call(week_start..week_end).merge(from: week_start.iso8601, to: week_end.iso8601),
              month: sum_for.call(month_start..month_end).merge(month: month_start.strftime('%Y-%m'), label: month_start.strftime('%B %Y')),
              daily: (month_start..month_end).map do |day|
                cell = daily.fetch(day, { liters: 0.0, deliveries: 0 })
                { date: day.iso8601, liters: cell[:liters].round(2), deliveries: cell[:deliveries] }
              end
            }
          }
        rescue => e
          render json: { success: false, message: e.message }, status: :internal_server_error
        end

        # PUT /api/v1/mobile/delivery/customers/:id/location
        def update_customer_location
          customer = Customer.find_by(id: params[:id])
          return render json: { success: false, message: "Customer not found" }, status: :not_found unless customer

          lat = params[:latitude]
          lng = params[:longitude]

          if lat.blank? || lng.blank?
            return render json: { success: false, message: "latitude and longitude are required" }, status: :unprocessable_entity
          end

          if customer.update(latitude: lat, longitude: lng, location_obtained_at: Time.current)
            render json: {
              success: true,
              message: "Customer location updated",
              data: { customer_id: customer.id, latitude: customer.latitude, longitude: customer.longitude }
            }
          else
            render json: { success: false, message: customer.errors.full_messages.join(", ") }, status: :unprocessable_entity
          end
        rescue => e
          render json: { success: false, message: e.message }, status: :internal_server_error
        end

        # POST /api/v1/mobile/delivery/customers/:id/upload_image
        def upload_customer_image
          customer = Customer.find_by(id: params[:id])
          return render json: { success: false, message: "Customer not found" }, status: :not_found unless customer

          image_file = params[:image]
          return render json: { success: false, message: "image is required" }, status: :unprocessable_entity unless image_file

          image_type = params[:image_type].presence_in(%w[profile house personal]) || "profile"

          begin
            result = Cloudinary::Uploader.upload(
              image_file.tempfile,
              folder: "customers/#{image_type}",
              public_id: "customers/#{image_type}/#{customer.id}-#{SecureRandom.hex(6)}",
              overwrite: true,
              resource_type: :image,
              transformation: [{ width: 1200, height: 1200, crop: :limit, quality: :auto, fetch_format: :auto }]
            )
            public_url = result["secure_url"]

            # Was re-downloading the image we just uploaded via URI.open(public_url) - a
            # second full network round trip for no reason. The local tempfile still has
            # the same bytes; just rewind and reuse it.
            attachment_name = { "profile" => :profile_image, "house" => :house_image, "personal" => :personal_image }[image_type]
            customer.send(attachment_name).attach(
              io: image_file.tempfile.tap(&:rewind),
              filename: "#{image_type}_#{customer.id}.jpg",
              content_type: "image/jpeg"
            ) if attachment_name

            render json: {
              success: true,
              message: "Image uploaded successfully",
              data: { customer_id: customer.id, image_type: image_type, image_url: public_url }
            }
          rescue => e
            Rails.logger.error "Customer image upload failed: #{e.message}"
            render json: { success: false, message: "Image upload failed: #{e.message}" }, status: :unprocessable_entity
          end
        end

        # GET /api/v1/mobile/delivery/customers/:id/location
        def get_customer_location
          customer = Customer.find_by(id: params[:id])
          return render json: { success: false, message: "Customer not found" }, status: :not_found unless customer

          render json: {
            success: true,
            data: {
              customer_id: customer.id,
              name: customer.display_name,
              address: customer.address,
              latitude: customer.latitude,
              longitude: customer.longitude,
              location_obtained_at: customer.location_obtained_at
            }
          }
        rescue => e
          render json: { success: false, message: e.message }, status: :internal_server_error
        end

        # GET /api/v1/mobile/delivery/customers/:id/images
        def get_customer_images
          customer = Customer.find_by(id: params[:id])
          return render json: { success: false, message: "Customer not found" }, status: :not_found unless customer

          render json: {
            success: true,
            data: {
              customer_id: customer.id,
              profile_image_url: customer.profile_image.attached? ? customer.profile_image.url : nil,
              personal_image_url: customer.personal_image.attached? ? customer.personal_image.url : nil,
              house_image_url: customer.house_image.attached? ? customer.house_image.url : nil
            }
          }
        rescue => e
          render json: { success: false, message: e.message }, status: :internal_server_error
        end

        # GET /api/v1/mobile/delivery/products
        def products
          paginate = params[:page].present? || params[:per_page].present?
          page = params[:page]&.to_i || 1
          per_page = params[:per_page]&.to_i || 20
          per_page = [per_page, 50].min

          @products = Product.active.in_stock

          @products = @products.where(category_id: params[:category_id]) if params[:category_id].present?
          @products = @products.where('price >= ?', params[:min_price]) if params[:min_price].present?
          @products = @products.where('price <= ?', params[:max_price]) if params[:max_price].present?
          @products = @products.search(params[:search]) if params[:search].present?

          case params[:sort_by]
          when 'price_low' then @products = @products.order(:price)
          when 'price_high' then @products = @products.order(price: :desc)
          when 'name' then @products = @products.order(:name)
          when 'newest' then @products = @products.recent
          when 'rating'
            @products = @products.joins(:product_reviews)
                                 .group('products.id')
                                 .order('AVG(product_reviews.rating) DESC NULLS LAST')
          else
            @products = @products.order(:name)
          end

          total_count = @products.count
          total_count = total_count.is_a?(Hash) ? total_count.keys.count : total_count
          @products = paginate ? @products.offset((page - 1) * per_page).limit(per_page) : @products
          @products = preload_product_listing(@products)

          products_data = @products.map { |product| format_product_data(product) }

          pagination_data = if paginate
            {
              current_page: page,
              per_page: per_page,
              total_count: total_count,
              total_pages: (total_count.to_f / per_page).ceil,
              has_next_page: page < (total_count.to_f / per_page).ceil,
              has_prev_page: page > 1
            }
          else
            {
              current_page: 1,
              per_page: total_count,
              total_count: total_count,
              total_pages: total_count.zero? ? 0 : 1,
              has_next_page: false,
              has_prev_page: false
            }
          end

          render json: {
            success: true,
            data: {
              products: products_data,
              pagination: pagination_data,
              applied_filters: {
                category_id: params[:category_id],
                min_price: params[:min_price],
                max_price: params[:max_price],
                search: params[:search],
                sort_by: params[:sort_by]
              }
            },
            message: 'Products retrieved successfully'
          }
        rescue => e
          render json: { success: false, message: e.message }, status: :internal_server_error
        end

        # GET /api/v1/mobile/delivery/products/:id
        def product_details
          product = Product.active
                            .includes(:category, :approved_reviews, :product_variants, image_attachment: :blob, additional_images_attachments: :blob)
                            .find(params[:id])

          render json: {
            success: true,
            data: format_product_data(product),
            message: 'Product details retrieved successfully'
          }
        rescue ActiveRecord::RecordNotFound
          render json: { success: false, message: 'Product not found' }, status: :not_found
        rescue => e
          render json: { success: false, message: e.message }, status: :internal_server_error
        end

        # POST /api/v1/mobile/delivery/bookings
        def create_booking
          customer_id      = params[:customer_id]
          delivery_address = params[:delivery_address]
          items            = params[:items]
          notes            = params[:notes]

          if customer_id.blank? || delivery_address.blank? || items.blank? || !items.is_a?(Array)
            return render json: {
              success: false,
              message: "customer_id, delivery_address, and items (array) are required"
            }, status: :unprocessable_entity
          end

          customer = Customer.find_by(id: customer_id)
          return render json: { success: false, message: "Customer not found" }, status: :not_found unless customer

          # Resolve products and build nested attributes - batch-loaded to avoid a
          # find_by per item (and reused below to avoid a second per-item lookup
          # when serializing booking.booking_items).
          products_by_id = Product.where(id: items.map { |item| item[:product_id] }).index_by { |p| p.id.to_s }

          nested_items = []
          items.each do |item|
            product = products_by_id[item[:product_id].to_s]
            unless product
              return render json: { success: false, message: "Product ##{item[:product_id]} not found" }, status: :unprocessable_entity
            end
            qty   = [item[:quantity].to_i, 1].max
            price = (product.discount_price.to_f > 0 ? product.discount_price : product.price).to_f
            nested_items << { product_id: product.id, quantity: qty, price: price }
          end

          booking = nil
          ActiveRecord::Base.transaction do
            booking = Booking.new(
              customer_id:             customer.id,
              customer_name:           customer.display_name,
              customer_phone:          customer.mobile,
              customer_email:          customer.email,
              delivery_address:        delivery_address,
              payment_method:          :cod,
              payment_status:          :unpaid,
              status:                  :ordered_and_delivery_pending,
              delivery_person_id:      current_delivery_person_id,
              booked_by:               'delivery_person',
              notes:                   notes,
              booking_date:            Date.current,
              booking_items_attributes: nested_items
            )
            booking.save!
          end

          booking.booking_items.each do |bi|
            product = products_by_id[bi.product_id.to_s]
            bi.association(:product).target = product if product
          end

          render json: {
            success: true,
            message: "Booking created successfully",
            data: {
              booking_id:     booking.id,
              booking_number: booking.booking_number,
              customer_name:  booking.customer_name,
              total_amount:   booking.total_amount,
              payment_method: "Cash on Delivery",
              payment_status: "Unpaid",
              status:         booking.status,
              items:          booking.booking_items.map { |bi|
                {
                  product_name: bi.product&.name,
                  quantity:     bi.quantity,
                  price:        bi.price,
                  subtotal:     bi.quantity * bi.price
                }
              }
            }
          }
        rescue ActiveRecord::RecordInvalid => e
          render json: { success: false, message: e.message }, status: :unprocessable_entity
        rescue => e
          render json: { success: false, message: e.message }, status: :internal_server_error
        end

        # POST /api/v1/mobile/delivery/bulk_update
        def bulk_update
          begin
            # Validate request
            if params[:updates].blank? || !params[:updates].is_a?(Array)
              render json: { success: false, message: "No updates provided" }, status: :bad_request
              return
            end

            delivery_person_id = params[:delivery_person_id] || current_delivery_person_id

            # Process each update
            results = process_bulk_updates(params[:updates], delivery_person_id)

            render json: {
              success: true,
              message: "#{results[:successful_updates]} deliveries updated successfully",
              data: {
                total_processed: results[:total_processed],
                successful_updates: results[:successful_updates],
                failed_updates: results[:failed_updates],
                results: results[:results],
                summary: results[:summary]
              }
            }
          rescue => e
            Rails.logger.error "Bulk update error: #{e.message}"
            render json: {
              success: false,
              message: "Failed to process bulk updates",
              error: Rails.env.development? ? e.message : nil
            }, status: :internal_server_error
          end
        end

        private

        # Returns an error string, or nil on success.
        def apply_task_operation(record, operation, now)
          if record.is_a?(Booking)
            return "Task is cancelled" if record.status == 'cancelled'
            if operation == 'complete'
              return "Already completed" if record.status == 'delivered'
              record.update!(status: 'delivered', delivery_time: now)
            else
              return "Cannot delete a delivered task" if record.status == 'delivered'
              record.update!(status: 'cancelled')
            end
          else
            return "Task is cancelled" if record.status == 'cancelled'
            if operation == 'complete'
              return "Already completed" if DELIVERED_STATUSES.include?(record.status)
              record.update!(status: 'completed', completed_at: now)
            else
              return "Cannot delete a delivered task" if DELIVERED_STATUSES.include?(record.status)
              record.update!(status: 'cancelled')
            end
          end
          nil
        end

        def parse_customer_month(value)
          return nil if value == 'all'
          return Date.current.beginning_of_month if value.blank?
          Date.strptime(value, '%Y-%m')
        rescue ArgumentError, TypeError
          Date.current.beginning_of_month
        end

        def parse_summary_date(value)
          value.present? ? Date.iso8601(value) : Date.current
        rescue ArgumentError
          Date.current
        end

        # Same preference as Customer#assigned_delivery_person: active subscription first.
        def subscription_delivery_person_id(subs)
          active = subs.find { |s| s.status == 'active' && s.delivery_person_id.present? }
          (active || subs.find { |s| s.delivery_person_id.present? })&.delivery_person_id
        end

        def quantity_in_liters(quantity, unit)
          liters = quantity.to_f
          %w[ml millilitre milliliter].include?(unit.to_s.downcase.strip) ? liters / 1000.0 : liters
        end

        def authenticate_delivery_person!
          # Implement your authentication logic here
          # This should check for valid delivery person JWT token
          unless valid_delivery_person_token?
            render json: { success: false, message: "Unauthorized: Invalid or expired token" }, status: :unauthorized
          end
        end

        def valid_delivery_person_token?
          # Check JWT token from Authorization header
          token = request.headers['Authorization']&.split(' ')&.last
          return false unless token

          # Decode and verify JWT token
          begin
            decoded_token = JWT.decode(token, Rails.application.secret_key_base, true, algorithm: 'HS256')
            @current_delivery_person = DeliveryPerson.find_by(id: decoded_token[0]['delivery_person_id'])
            @current_delivery_person.present?
          rescue JWT::DecodeError, JWT::ExpiredSignature
            false
          end
        end

        def current_delivery_person_id
          @current_delivery_person&.id
        end

        def get_todays_tasks
          # Get all bookings/orders assigned to current delivery person for today
          begin
            if defined?(Booking) && Booking.column_names.include?('delivery_person_id')
              bookings = Booking.where(delivery_person_id: current_delivery_person_id)
                              .where('DATE(created_at) = ?', Date.current)
                              .where.not(status: 'cancelled')
                              .includes(:customer, booking_items: :product)
                              .to_a
            else
              bookings = []
            end
          rescue => e
            Rails.logger.error "Error fetching bookings: #{e.message}"
            bookings = []
          end

          # Also get subscription deliveries for today (including completed ones)
          begin
            if defined?(MilkDeliveryTask) && MilkDeliveryTask.column_names.include?('delivery_person_id')
              subscription_tasks = MilkDeliveryTask.where(
                delivery_person_id: current_delivery_person_id,
                delivery_date: Date.current
              ).where.not(status: %w[cancelled paused]).includes(:customer, :product).to_a
            else
              subscription_tasks = []
            end
          rescue => e
            Rails.logger.error "Error fetching subscription tasks: #{e.message}"
            subscription_tasks = []
          end

          # Combine both types of tasks
          { bookings: bookings, subscriptions: subscription_tasks }
        end

        def task_summary(tasks)
          bookings = Array(tasks[:bookings])
          subscriptions = Array(tasks[:subscriptions])

          total = bookings.size + subscriptions.size
          completed = bookings.count { |b| b.status == 'delivered' } + subscriptions.count { |s| s.status == 'completed' }
          pending = total - completed

          total_collection = calculate_total_collection(bookings)

          {
            total_tasks: total,
            completed: completed,
            pending: pending,
            failed: 0,
            total_collection: total_collection
          }
        end

        def calculate_total_collection(bookings)
          return 0 if bookings.empty?
          bookings.select { |b| b.payment_method == 'cash' }.sum(&:total_amount) || 0
        rescue => e
          Rails.logger.error "Error calculating total collection: #{e.message}"
          0
        end

        def format_tasks(tasks)
          entries = Array(tasks[:bookings]).map { |b| [b.customer, format_booking_task(b)] } +
                    Array(tasks[:subscriptions]).map { |t| [t.customer, format_subscription_task(t)] }

          # Pending/in-progress tasks first, completed ones pushed to the bottom. Within each
          # group, follow the customer order from /admin/customer_orders (row_number, then
          # name; customers without a row number last). The index keeps the sort stable.
          entries
            .each_with_index
            .sort_by do |(customer, task), index|
              row = customer&.row_number
              [task[:status] == 'completed' ? 1 : 0,
               row.nil? ? 1 : 0, row.to_i,
               customer&.first_name.to_s.downcase, customer&.last_name.to_s.downcase,
               index]
            end
            .each_with_index
            .map { |((customer, task), _), i| task.merge(row_number: customer&.row_number, serial: i + 1) }
        end

        def format_booking_task(booking)
          {
            id: booking.id,
            type: "order",
            order_number: booking.booking_number,
            customer: {
              name: booking.customer_name,
              mobile: booking.customer_phone,
              address: booking.delivery_address,
              landmark: booking.respond_to?(:landmark) ? booking.landmark : nil,
              pincode: booking.respond_to?(:pincode) ? booking.pincode : nil,
              latitude: booking.respond_to?(:latitude) ? booking.latitude : nil,
              longitude: booking.respond_to?(:longitude) ? booking.longitude : nil
            }.merge(format_customer_images(booking.customer)),
            items: booking.respond_to?(:booking_items) && booking.booking_items ? booking.booking_items.map { |item|
              {
                product_name: item.product&.name,
                quantity: item.quantity,
                unit: item.product&.unit_type || item.product&.unit || 'piece'
              }
            } : [],
            payment: {
              method: booking.payment_method,
              amount_to_collect: booking.payment_method == 'cash' ? booking.total_amount : 0,
              status: booking.payment_status
            },
            delivery_slot: booking.respond_to?(:delivery_slot) ? (booking.delivery_slot || "10:00 AM - 12:00 PM") : "10:00 AM - 12:00 PM",
            priority: "normal",
            status: map_booking_status(booking.status),
            special_instructions: booking.notes
          }
        end

        def format_subscription_task(subscription)
          {
            id: subscription.id,
            type: "subscription",
            order_number: "SUB-#{subscription.id}",
            customer: {
              name: subscription.customer&.display_name,
              mobile: subscription.customer&.mobile,
              address: subscription.customer&.address,
              pincode: subscription.customer&.respond_to?(:pincode) ? subscription.customer&.pincode : nil,
              latitude: subscription.customer&.latitude,
              longitude: subscription.customer&.longitude
            }.merge(format_customer_images(subscription.customer)),
            items: [
              {
                product_name: subscription.product&.name,
                quantity: subscription.quantity,
                unit: subscription.unit
              }
            ],
            payment: {
              method: "prepaid",
              amount_to_collect: 0,
              status: "paid"
            },
            delivery_slot: subscription.respond_to?(:delivery_time) ? subscription.delivery_time : "07:00 AM - 09:00 AM",
            priority: "normal",
            status: subscription.status,
            special_instructions: nil
          }
        end

        def map_booking_status(status)
          case status
          when 'ordered_and_delivery_pending' then 'pending'
          when 'out_for_delivery' then 'in_progress'
          when 'delivered' then 'completed'
          else status
          end
        end

        def route_optimization(tasks, formatted_tasks)
          total_tasks = tasks[:bookings].count + tasks[:subscriptions].count

          {
            suggested_sequence: formatted_tasks.first(3).map { |t| t[:id] },
            estimated_completion_time: "#{(total_tasks * 15)} minutes",
            total_distance: "#{(total_tasks * 2)} km"
          }
        end

        def find_task(task_id)
          # First try to find in bookings
          booking = Booking.find_by(id: task_id)
          return booking if booking

          # Then try subscription tasks
          MilkDeliveryTask.find_by(id: task_id)
        end

        def format_task_details(task)
          if task.is_a?(Booking)
            format_booking_task(task)
          else
            format_subscription_task(task)
          end
        end

        def update_task_status(task, status)
          if task.is_a?(Booking)
            task.update(status: 'out_for_delivery')
          else
            task.update(status: 'assigned')
          end
        end

        def complete_delivery(task, params)
          ActiveRecord::Base.transaction do
            if task.is_a?(Booking)
              # Update booking status
              task.update!(
                status: 'delivered',
                delivery_time: Time.current,
                transition_notes: params.dig(:notes),
                payment_status: params.dig(:payment_collected, :amount) ? 'paid' : task.payment_status
              )

              # Record payment if COD
              if params.dig(:payment_collected, :amount)
                record_payment(task, params[:payment_collected])
              end
            else
              # Update subscription task
              task.update!(
                status: 'completed',
                completed_at: Time.current
              )
            end

            true
          end
        rescue => e
          Rails.logger.error "Failed to complete delivery: #{e.message}"
          false
        end

        def record_payment(booking, payment_info)
          # Record payment collection
          # Implement your payment recording logic here
        end

        def get_next_task_id
          # Get next pending task for the delivery person
          next_task = Booking.where(
            delivery_person_id: current_delivery_person_id,
            status: ['ordered_and_delivery_pending', 'confirmed']
          ).where('DATE(created_at) = ?', Date.current).first

          next_task&.id || MilkDeliveryTask.where(
            delivery_person_id: current_delivery_person_id,
            delivery_date: Date.current,
            status: 'pending'
          ).first&.id
        end

        def update_delivery_location(latitude, longitude)
          # Update delivery person's current location
          # This could be stored in Redis or a location tracking table
          true
        end

        def calculate_distance_to_customer(task, lat, lng)
          # Simple distance calculation
          # In production, use proper distance calculation algorithm
          if task.respond_to?(:latitude) && task.respond_to?(:longitude)
            # Simplified distance calculation
            500 # Return 500 meters as example
          else
            1000 # Default 1km if no coordinates
          end
        end

        def estimate_arrival_time
          (Time.current + 15.minutes).strftime("%I:%M %p")
        end

        def format_customer(customer)
          {
            id:          customer.id,
            name:        customer.display_name,
            mobile:      customer.mobile,
            email:       customer.email,
            address:     customer.address,
            latitude:    customer.latitude,
            longitude:   customer.longitude,
            whatsapp:    customer.whatsapp_number,
            row_number:  customer.row_number,
            is_image_uploaded: customer.profile_image.attached? ||
                                customer.personal_image.attached? ||
                                customer.house_image.attached?
          }
        end

        # Every attached customer image, plus which one is "primary" (profile
        # image if uploaded, otherwise whichever image was uploaded first).
        def format_customer_images(customer)
          return { images: [], primary_image_url: nil } unless customer

          images = []
          images << { type: 'profile', url: customer.profile_image.url } if customer.profile_image.attached?
          images << { type: 'house', url: customer.house_image.url } if customer.house_image.attached?
          images << { type: 'personal', url: customer.personal_image.url } if customer.personal_image.attached?

          primary = images.find { |img| img[:type] == 'profile' } || images.first
          images.each { |img| img[:is_primary] = img.equal?(primary) }

          { images: images, primary_image_url: primary&.fetch(:url) }
        end

        def process_bulk_delivery_update(delivery_ids, delivery_person_id, completed_at)
          updated_ids = []
          failed_ids = []
          errors = []

          bookings_by_id = Booking.where(id: delivery_ids).index_by(&:id)
          remaining_ids = delivery_ids - bookings_by_id.keys
          tasks_by_id = MilkDeliveryTask.where(id: remaining_ids).index_by(&:id)

          delivery_ids.each do |id|
            begin
              # Try to find and update booking
              booking = bookings_by_id[id]

              if booking.nil?
                # Try subscription task
                task = tasks_by_id[id]

                if task.nil?
                  failed_ids << id
                  errors << { id: id, error: "Delivery not found" }
                elsif task.status == 'completed'
                  failed_ids << id
                  errors << { id: id, error: "Already completed" }
                else
                  task.update!(
                    status: 'completed',
                    completed_at: completed_at,
                    delivery_person_id: delivery_person_id
                  )
                  updated_ids << id
                end
              elsif booking.status == 'delivered'
                failed_ids << id
                errors << { id: id, error: "Already completed" }
              else
                booking.update!(
                  status: 'delivered',
                  delivery_time: completed_at,
                  delivery_person_id: delivery_person_id
                )
                updated_ids << id
              end
            rescue => e
              failed_ids << id
              errors << { id: id, error: e.message }
            end
          end

          {
            updated_count: updated_ids.count,
            updated_delivery_ids: updated_ids,
            failed_ids: failed_ids.presence,
            errors: errors.presence
          }.compact
        end

        def process_bulk_updates(updates, delivery_person_id)
          results = []
          successful = 0
          failed = 0
          delivered_count = 0
          failed_delivery_count = 0

          bookings_by_id = Booking.where(id: updates.map { |u| u[:booking_id] }).index_by(&:id)

          updates.each do |update|
            booking_id = update[:booking_id]
            booking = bookings_by_id[booking_id.to_i]

            if booking.nil?
              results << {
                booking_id: booking_id,
                status: "error",
                message: "Booking not found"
              }
              failed += 1
            elsif update[:status] == 'delivered'
              if booking.update(
                status: 'delivered',
                delivery_time: update[:delivered_at] || Time.current,
                transition_notes: update[:delivery_notes],
                delivery_person_id: delivery_person_id
              )
                results << {
                  booking_id: booking_id,
                  status: "success",
                  message: "Delivery marked as completed",
                  booking_number: booking.booking_number
                }
                successful += 1
                delivered_count += 1
              else
                results << {
                  booking_id: booking_id,
                  status: "error",
                  message: booking.errors.full_messages.join(", ")
                }
                failed += 1
              end
            elsif update[:status] == 'failed'
              if booking.update(
                status: 'failed_delivery',
                failed_at: update[:attempted_at] || Time.current,
                failure_reason: update[:failure_reason],
                delivery_person_id: delivery_person_id
              )
                results << {
                  booking_id: booking_id,
                  status: "success",
                  message: "Delivery marked as failed",
                  booking_number: booking.booking_number
                }
                successful += 1
                failed_delivery_count += 1
              else
                results << {
                  booking_id: booking_id,
                  status: "error",
                  message: booking.errors.full_messages.join(", ")
                }
                failed += 1
              end
            else
              results << {
                booking_id: booking_id,
                status: "error",
                message: "Invalid status"
              }
              failed += 1
            end
          end

          {
            total_processed: updates.count,
            successful_updates: successful,
            failed_updates: failed,
            results: results,
            summary: {
              delivered_count: delivered_count,
              failed_count: failed_delivery_count,
              pending_count: 0
            }
          }
        end
      end
    end
  end
end