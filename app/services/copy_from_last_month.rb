class CopyFromLastMonth
  # Usage in rails console:
  #   CopyFromLastMonth.month(8)
  #
  # Copies every MilkSubscription that had delivery tasks in the prior month
  # (e.g. July when you pass 8) into the target month, with a fresh
  # subscription record and one MilkDeliveryTask per copied July task,
  # each shifted by 1 month and forced to status 'pending'.
  #
  # The whole run is one all-or-nothing transaction: if any subscription
  # fails to copy, everything created so far in this run is rolled back
  # and the failure reason is printed.
  def self.month(target_month, target_year = Date.current.year)
    target_start = Date.new(target_year, target_month, 1)
    target_end   = target_start.end_of_month

    source_start = target_start - 1.month
    source_end   = source_start.end_of_month

    subscription_ids = MilkDeliveryTask
                          .where(delivery_date: source_start..source_end)
                          .where.not(subscription_id: nil)
                          .distinct
                          .pluck(:subscription_id)

    created_subscriptions = 0
    created_tasks = 0
    skipped_subscriptions = 0

    begin
      ActiveRecord::Base.transaction do
        MilkSubscription.where(id: subscription_ids).find_each do |source_sub|
          source_tasks = source_sub.milk_delivery_tasks.where(delivery_date: source_start..source_end)

          tasks_to_copy = source_tasks.reject do |t|
            shifted_date = t.delivery_date + 1.month
            MilkDeliveryTask.exists?(customer_id: t.customer_id, product_id: t.product_id, delivery_date: shifted_date)
          end

          if tasks_to_copy.empty?
            skipped_subscriptions += 1
            next
          end

          begin
            new_sub = MilkSubscription.new(
              customer_id:        source_sub.customer_id,
              product_id:         source_sub.product_id,
              quantity:           source_sub.quantity,
              unit:                source_sub.unit,
              start_date:         target_start,
              end_date:           [source_sub.end_date + 1.month, target_end].min,
              delivery_time:      source_sub.delivery_time,
              delivery_pattern:   source_sub.delivery_pattern,
              specific_dates:     source_sub.specific_dates,
              delivery_person_id: source_sub.delivery_person_id,
              status:             'active',
              is_active:          true,
              created_by:         source_sub.created_by
            )

            # Skip the pattern-based auto-generation callback; we copy the real
            # prior-month tasks 1:1 below instead of re-deriving them from the pattern.
            new_sub.define_singleton_method(:generate_all_delivery_tasks) { true }
            new_sub.save!

            tasks_to_copy.each do |t|
              new_sub.milk_delivery_tasks.create!(
                customer_id:        t.customer_id,
                product_id:         t.product_id,
                quantity:           t.quantity,
                unit:               t.unit,
                delivery_date:      t.delivery_date + 1.month,
                delivery_person_id: t.delivery_person_id,
                status:             'pending'
              )
              created_tasks += 1
            end

            created_subscriptions += 1
          rescue => e
            reason = e.is_a?(ActiveRecord::RecordInvalid) ? e.record.errors.full_messages.join(', ') : e.message
            raise "Subscription ##{source_sub.id} (customer_id: #{source_sub.customer_id}, " \
                  "product_id: #{source_sub.product_id}) failed: #{reason}"
          end
        end
      end
    rescue => e
      print_failure_summary(source_start, target_start, e.message)
      return { success: false, error: e.message, subscriptions: 0, tasks: 0 }
    end

    print_success_summary(source_start, target_start, created_subscriptions, created_tasks, skipped_subscriptions)

    { success: true, subscriptions: created_subscriptions, tasks: created_tasks, skipped: skipped_subscriptions }
  end

  def self.print_success_summary(source_start, target_start, created_subscriptions, created_tasks, skipped_subscriptions)
    puts ""
    puts "=" * 60
    puts "CopyFromLastMonth summary — SUCCESS"
    puts "=" * 60
    puts "Source month:          #{source_start.strftime('%B %Y')}"
    puts "Target month:          #{target_start.strftime('%B %Y')}"
    puts "Subscriptions copied:  #{created_subscriptions}"
    puts "Delivery tasks copied: #{created_tasks}"
    puts "Subscriptions skipped: #{skipped_subscriptions} (already had copies)"
    puts "=" * 60
  end
  private_class_method :print_success_summary

  def self.print_failure_summary(source_start, target_start, reason)
    puts ""
    puts "=" * 60
    puts "CopyFromLastMonth summary — FAILED, everything rolled back"
    puts "=" * 60
    puts "Source month: #{source_start.strftime('%B %Y')}"
    puts "Target month: #{target_start.strftime('%B %Y')}"
    puts "Reason:       #{reason}"
    puts "=" * 60
  end
  private_class_method :print_failure_summary
end
