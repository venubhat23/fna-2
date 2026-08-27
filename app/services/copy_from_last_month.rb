class CopyFromLastMonth
  # Usage in rails console:
  #   CopyFromLastMonth.month(8)
  #
  # Phase 1: copies every MilkSubscription that had delivery tasks in the
  # prior month (e.g. July when you pass 8) into the target month, with a
  # fresh subscription record and one MilkDeliveryTask per copied July task,
  # each shifted by 1 month and forced to status 'pending'.
  #
  # Phase 2: catches customers who wouldn't be picked up by phase 1 at all —
  # e.g. a customer added to CustomerFormat after last month's tasks were
  # generated. For every active CustomerFormat with no delivery task in the
  # target month yet, it creates a subscription and generates that month's
  # tasks from the format's own pattern (same pattern -> dates logic as
  # ImportMasterSubscriptionJob, since CustomerFormat's patterns don't map
  # onto MilkSubscription's own delivery_pattern enum).
  #
  # Each subscription/task and each customer-format subscription/task commits
  # on its own (no single enclosing transaction spanning the whole run). The
  # remote DB connection is flaky (drops mid-run under load), so a failure on
  # one record is logged and the run moves on to the next one instead of
  # aborting — every failure is printed as it happens and collected in the
  # final summary/return value. If the connection itself dropped, it's
  # verified/reconnected before continuing so later records aren't skipped
  # just because of a transient blip. Since every step here skips work
  # that's already been done, it's also safe to just call .month again
  # afterwards to pick up anything still missing (including retrying
  # whatever failed this time).
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
    created_format_subscriptions = 0
    created_format_tasks = 0
    skipped_formats = 0
    failures = []

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
        failure = "Subscription ##{source_sub.id} (customer_id: #{source_sub.customer_id}, " \
                  "product_id: #{source_sub.product_id}) failed: #{reason}"
        failures << failure
        puts "  [FAILED] #{failure}"
        recover_connection!
      end
    end

    CustomerFormat.active.includes(:customer, :product, :delivery_person).find_each do |cf|
      has_target_task = MilkDeliveryTask.exists?(
        customer_id: cf.customer_id,
        product_id: cf.product_id,
        delivery_date: target_start..target_end
      )

      if has_target_task
        skipped_formats += 1
        next
      end

      task_dates = calculate_task_dates(cf, target_start, target_end)

      if task_dates.empty?
        skipped_formats += 1
        next
      end

      begin
        new_sub = MilkSubscription.new(
          customer_id:        cf.customer_id,
          product_id:         cf.product_id,
          delivery_person_id: cf.delivery_person_id,
          quantity:           cf.quantity,
          unit:                'liter',
          start_date:         target_start,
          end_date:           target_end,
          delivery_time:      '07:00',
          status:             'active',
          is_active:          true
        )

        # Skip auto-generation; it only knows daily/alternate/specific_dates,
        # not CustomerFormat's pattern vocabulary, so we insert the correct
        # dates ourselves below.
        new_sub.define_singleton_method(:generate_all_delivery_tasks) { true }
        new_sub.save!

        task_dates.each do |date|
          new_sub.milk_delivery_tasks.create!(
            customer_id:        cf.customer_id,
            product_id:         cf.product_id,
            quantity:           cf.quantity,
            unit:               'liter',
            delivery_date:      date,
            delivery_person_id: cf.delivery_person_id,
            status:             'pending'
          )
          created_format_tasks += 1
        end

        created_format_subscriptions += 1
      rescue => e
        reason = e.is_a?(ActiveRecord::RecordInvalid) ? e.record.errors.full_messages.join(', ') : e.message
        failure = "CustomerFormat ##{cf.id} (customer_id: #{cf.customer_id}, " \
                  "product_id: #{cf.product_id}) failed: #{reason}"
        failures << failure
        puts "  [FAILED] #{failure}"
        recover_connection!
      end
    end

    print_summary(
      source_start, target_start,
      created_subscriptions, created_tasks, skipped_subscriptions,
      created_format_subscriptions, created_format_tasks, skipped_formats,
      failures
    )

    {
      success: failures.empty?,
      subscriptions: created_subscriptions,
      tasks: created_tasks,
      skipped: skipped_subscriptions,
      format_subscriptions: created_format_subscriptions,
      format_tasks: created_format_tasks,
      format_skipped: skipped_formats,
      failures: failures
    }
  end

  # Re-establishes the DB connection if the last error left it dead, so the
  # next iteration doesn't just immediately fail again on the same stale
  # connection. Safe to call even if the connection is actually still fine.
  def self.recover_connection!
    ActiveRecord::Base.connection.verify!
  rescue => e
    puts "  [WARN] could not verify/reconnect DB connection: #{e.message}"
  end
  private_class_method :recover_connection!

  def self.calculate_task_dates(customer_format, start_date, end_date)
    case customer_format.pattern
    when 'every_day'
      (start_date..end_date).to_a
    when 'alternative_day'
      dates = []
      current_date = start_date
      day_counter = 1
      while current_date <= end_date
        dates << current_date if day_counter.odd?
        current_date += 1.day
        day_counter += 1
      end
      dates
    when 'weekly_once'   then calculate_weekly_tasks(start_date, end_date, 1)
    when 'weekly_twice'  then calculate_weekly_tasks(start_date, end_date, 2)
    when 'weekly_thrice' then calculate_weekly_tasks(start_date, end_date, 3)
    when 'weekly_four'   then calculate_weekly_tasks(start_date, end_date, 4)
    when 'weekly_five'   then calculate_weekly_tasks(start_date, end_date, 5)
    when 'weekly_six'    then calculate_weekly_tasks(start_date, end_date, 6)
    when 'random'
      selected_days = customer_format.selected_days
      return [] if selected_days.empty?
      (start_date..end_date).select { |date| selected_days.include?(date.day) }
    else
      []
    end
  end
  private_class_method :calculate_task_dates

  def self.calculate_weekly_tasks(start_date, end_date, tasks_per_week)
    dates = []
    current_week_start = start_date.beginning_of_week

    while current_week_start <= end_date
      week_end = [current_week_start.end_of_week, end_date].min
      week_dates = (current_week_start..week_end).select do |date|
        date >= start_date && date <= end_date && date.wday.between?(1, 5)
      end
      dates.concat(week_dates.take(tasks_per_week))
      current_week_start += 1.week
    end

    dates
  end
  private_class_method :calculate_weekly_tasks

  def self.print_summary(
    source_start, target_start,
    created_subscriptions, created_tasks, skipped_subscriptions,
    created_format_subscriptions, created_format_tasks, skipped_formats,
    failures
  )
    puts ""
    puts "=" * 60
    puts "CopyFromLastMonth summary — #{failures.empty? ? 'SUCCESS' : "COMPLETED WITH #{failures.size} FAILURE(S)"}"
    puts "=" * 60
    puts "Source month:          #{source_start.strftime('%B %Y')}"
    puts "Target month:          #{target_start.strftime('%B %Y')}"
    puts "-- Phase 1: copied from last month's tasks --"
    puts "Subscriptions copied:  #{created_subscriptions}"
    puts "Delivery tasks copied: #{created_tasks}"
    puts "Subscriptions skipped: #{skipped_subscriptions} (already had copies)"
    puts "-- Phase 2: filled in from Customer Format --"
    puts "Subscriptions added:   #{created_format_subscriptions}"
    puts "Delivery tasks added:  #{created_format_tasks}"
    puts "Formats skipped:       #{skipped_formats} (already covered or no dates for pattern)"
    if failures.any?
      puts "-- Failures (#{failures.size}) --"
      failures.each { |f| puts "  #{f}" }
      puts "Safe to re-run CopyFromLastMonth.month — everything above was already skipped correctly, and it'll retry only what failed/is still missing."
    end
    puts "=" * 60
  end
  private_class_method :print_summary
end
