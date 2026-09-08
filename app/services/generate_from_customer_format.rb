class GenerateFromCustomerFormat
  # Usage in rails console:
  #   GenerateFromCustomerFormat.month           # current month/year
  #   GenerateFromCustomerFormat.month(9)        # month 9 of the current year
  #   GenerateFromCustomerFormat.month(8, 2026)  # explicit month + year
  #
  # This is the "generate straight from Customer Format" routine — the
  # alternative to CopyFromLastMonth, which instead clones the prior month's
  # delivery tasks. Here nothing is copied: for every active CustomerFormat we
  # take the format's own pattern (every_day, alternative_day, weekly_*,
  # random) and materialise this month's delivery dates from it.
  #
  # For each active CustomerFormat:
  #   1. Expand the pattern into the list of dates it wants in the target month
  #      (same pattern -> dates logic as ImportMasterSubscriptionJob, since
  #      CustomerFormat's pattern vocabulary doesn't map onto MilkSubscription's
  #      own delivery_pattern enum).
  #   2. Drop any date that already has a MilkDeliveryTask for that
  #      customer/product (PER DATE, not "any task in the month") — so a
  #      partially-filled month gets its remaining gaps filled instead of being
  #      skipped wholesale.
  #   3. If dates remain, reuse this month's subscription for that
  #      customer/product if one already exists (e.g. from an earlier run that
  #      died partway), otherwise create one, and add one 'pending' task per
  #      still-missing date.
  #
  # Resilience (same as CopyFromLastMonth): each format's subscription + tasks
  # commit on their own, with no enclosing transaction over the whole run. The
  # remote DB connection is flaky under load, so a failure on one format is
  # logged and the run moves on; if the connection itself dropped it's
  # verified/reconnected before the next format. Every step skips work that's
  # already done, so it's safe to just call .month again to pick up anything
  # still missing (including retrying whatever failed).
  def self.month(target_month = Date.current.month, target_year = Date.current.year)
    target_start = Date.new(target_year, target_month, 1)
    target_end   = target_start.end_of_month

    created_subscriptions = 0
    resumed_subscriptions = 0
    created_tasks = 0
    skipped_formats = 0
    failures = []

    CustomerFormat.active.includes(:customer, :product, :delivery_person).find_each do |cf|
      wanted_dates = calculate_task_dates(cf, target_start, target_end)

      if wanted_dates.empty?
        skipped_formats += 1
        next
      end

      missing_dates = wanted_dates.reject do |date|
        MilkDeliveryTask.exists?(
          customer_id: cf.customer_id,
          product_id:  cf.product_id,
          delivery_date: date
        )
      end

      if missing_dates.empty?
        skipped_formats += 1
        next
      end

      begin
        # An earlier interrupted run may have already created this month's
        # subscription for this customer/product before dying. Reuse it instead
        # of creating a duplicate — only the still-missing dates get added below.
        existing_sub = MilkSubscription.find_by(
          customer_id: cf.customer_id,
          product_id:  cf.product_id,
          start_date:  target_start
        )

        if existing_sub
          new_sub = existing_sub
        else
          new_sub = MilkSubscription.new(
            customer_id:        cf.customer_id,
            product_id:         cf.product_id,
            delivery_person_id: cf.delivery_person_id,
            quantity:           cf.quantity,
            unit:               'liter',
            start_date:         target_start,
            end_date:           target_end,
            delivery_time:      '07:00',
            status:             'active',
            is_active:          true
          )

          # Skip the pattern-based auto-generation callback; it only knows
          # daily/alternate/specific_dates, not CustomerFormat's pattern
          # vocabulary, so we insert the correct dates ourselves below.
          new_sub.define_singleton_method(:generate_all_delivery_tasks) { true }
          new_sub.save!
        end

        missing_dates.each do |date|
          new_sub.milk_delivery_tasks.create!(
            customer_id:        cf.customer_id,
            product_id:         cf.product_id,
            quantity:           cf.quantity,
            unit:               'liter',
            delivery_date:      date,
            delivery_person_id: cf.delivery_person_id,
            status:             'pending'
          )
          created_tasks += 1
        end

        existing_sub ? (resumed_subscriptions += 1) : (created_subscriptions += 1)
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
      target_start,
      created_subscriptions, resumed_subscriptions, created_tasks, skipped_formats,
      failures
    )

    {
      success: failures.empty?,
      subscriptions: created_subscriptions,
      resumed_subscriptions: resumed_subscriptions,
      tasks: created_tasks,
      skipped_formats: skipped_formats,
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
    target_start,
    created_subscriptions, resumed_subscriptions, created_tasks, skipped_formats,
    failures
  )
    puts ""
    puts "=" * 60
    puts "GenerateFromCustomerFormat summary — #{failures.empty? ? 'SUCCESS' : "COMPLETED WITH #{failures.size} FAILURE(S)"}"
    puts "=" * 60
    puts "Target month:          #{target_start.strftime('%B %Y')}"
    puts "Subscriptions created: #{created_subscriptions}"
    puts "Subscriptions resumed: #{resumed_subscriptions} (already existed from an earlier run; missing tasks added, no duplicate created)"
    puts "Delivery tasks created: #{created_tasks}"
    puts "Formats skipped:       #{skipped_formats} (no dates for pattern, or every wanted date already had a task)"
    if failures.any?
      puts "-- Failures (#{failures.size}) --"
      failures.each { |f| puts "  #{f}" }
      puts "Safe to re-run GenerateFromCustomerFormat.month — everything above was already skipped correctly, and it'll retry only what failed/is still missing."
    end
    puts "=" * 60
  end
  private_class_method :print_summary
end
