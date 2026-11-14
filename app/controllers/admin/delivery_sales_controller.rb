class Admin::DeliverySalesController < Admin::ApplicationController
  before_action :check_sidebar_permission

  # A task counts as "sold" once it has actually been delivered.
  SOLD_STATUSES = %w[delivered completed].freeze
  TREND_DAYS = 14
  TREND_PEOPLE = 6
  # A custom range up to this many days replaces the trend chart's last-14-days window.
  MAX_TREND_RANGE_DAYS = 92

  # Milk volume delivered per delivery person for a day, its week (Mon-Sun) and its month.
  def index
    @date = parse_date(params[:date])
    @week_start = @date.beginning_of_week(:monday)
    @week_end = @week_start + 6
    @month_start = @date.beginning_of_month
    @month_end = @date.end_of_month
    @range_from, @range_to = parse_range(params[:from], params[:to])
    @range_days = @range_from ? (@range_to - @range_from).to_i + 1 : 0

    if @range_from && @range_days.between?(2, MAX_TREND_RANGE_DAYS)
      @trend_start, @trend_end = @range_from, @range_to
    else
      @trend_start, @trend_end = @date - (TREND_DAYS - 1), @date
    end

    daily = daily_volumes(
      [@month_start, @week_start, @trend_start, @range_from].compact.min,
      [@month_end, @week_end, @trend_end, @range_to].compact.max
    )

    @people = build_people(daily)
    @periods = @range_from ? %i[day week month range] : %i[day week month]
    @totals = @periods.index_with { |period| @people.sum { |p| p[period][:liters] }.round(1) }
    @delivery_counts = @periods.index_with { |period| @people.sum { |p| p[period][:deliveries] } }
    @trend_dates = (@trend_start..@trend_end).to_a
    @chart_data = chart_data
  end

  private

  # { person_id => { date => { liters:, deliveries: } } } from one grouped query.
  def daily_volumes(from, to)
    rows = MilkDeliveryTask
      .where(status: SOLD_STATUSES, delivery_date: from..to)
      .where.not(delivery_person_id: nil)
      .group(:delivery_person_id, :delivery_date, :unit)
      .pluck(:delivery_person_id, :delivery_date, :unit, Arel.sql('SUM(quantity)'), Arel.sql('COUNT(*)'))

    rows.each_with_object(Hash.new { |h, k| h[k] = Hash.new { |hh, kk| hh[kk] = { liters: 0.0, deliveries: 0 } } }) do |(person_id, date, unit, qty, count), acc|
      cell = acc[person_id][date]
      cell[:liters] += to_liters(qty, unit)
      cell[:deliveries] += count
    end
  end

  def to_liters(quantity, unit)
    liters = quantity.to_f
    %w[ml millilitre milliliter].include?(unit.to_s.downcase.strip) ? liters / 1000.0 : liters
  end

  def build_people(daily)
    people = DeliveryPerson.active.or(DeliveryPerson.where(id: daily.keys)).to_a

    entries = people.map do |person|
      days = daily[person.id]
      {
        id: person.id,
        name: "#{person.first_name} #{person.last_name}".strip,
        mobile: person.mobile,
        active: person.status,
        day: sum_range(days, @date..@date),
        week: sum_range(days, @week_start..@week_end),
        month: sum_range(days, @month_start..@month_end),
        range: @range_from ? sum_range(days, @range_from..@range_to) : { liters: 0.0, deliveries: 0 },
        trend: (@trend_start..@trend_end).map { |d| days.key?(d) ? days[d][:liters].round(1) : 0 }
      }
    end

    # With a custom range picked, rank by it; otherwise by the month.
    entries.sort_by { |e| [-e[:range][:liters], -e[:month][:liters], -e[:week][:liters], e[:name].downcase] }
  end

  def sum_range(days, range)
    cells = days.select { |date, _| range.cover?(date) }.values
    { liters: cells.sum { |c| c[:liters] }.round(1), deliveries: cells.sum { |c| c[:deliveries] } }
  end

  def chart_data
    top = @people.first(TREND_PEOPLE).select { |p| p[:trend].sum.positive? }
    others = @people - top
    series = top.map { |p| { label: p[:name], data: p[:trend] } }
    other_totals = @trend_dates.each_index.map { |i| others.sum { |p| p[:trend][i] }.round(1) }
    series << { label: 'Others', data: other_totals } if other_totals.any?(&:positive?)

    ranked = @people.select { |p| @periods.any? { |period| p[period][:liters].positive? } }.first(15)
    {
      trend: { labels: @trend_dates.map { |d| d.strftime('%-d %b') }, series: series },
      ranking: {
        labels: ranked.map { |p| p[:name] },
        day: ranked.map { |p| p[:day][:liters] },
        week: ranked.map { |p| p[:week][:liters] },
        month: ranked.map { |p| p[:month][:liters] },
        range: ranked.map { |p| p[:range][:liters] }
      }
    }
  end

  def parse_date(value)
    value.present? ? Date.iso8601(value) : Date.current
  rescue ArgumentError
    Date.current
  end

  # Both ends are needed; a reversed range is swapped and nothing past today is kept.
  def parse_range(from, to)
    return [nil, nil] if from.blank? || to.blank?

    from, to = [Date.iso8601(from), Date.iso8601(to)].sort
    to = [to, Date.current].min
    from <= to ? [from, to] : [nil, nil]
  rescue ArgumentError
    [nil, nil]
  end

  def check_sidebar_permission
    return if current_user&.has_sidebar_permission?('subscriptions')

    redirect_to admin_dashboard_path, alert: 'You do not have permission to access this page.'
  end
end
