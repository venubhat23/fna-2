class Admin::DeliverySalesController < Admin::ApplicationController
  before_action :check_sidebar_permission

  # A task counts as "sold" once it has actually been delivered.
  SOLD_STATUSES = %w[delivered completed].freeze
  TREND_DAYS = 14
  TREND_PEOPLE = 6

  # Milk volume delivered per delivery person for a day, its week (Mon-Sun) and its month.
  def index
    @date = parse_date(params[:date])
    @week_start = @date.beginning_of_week(:monday)
    @week_end = @week_start + 6
    @month_start = @date.beginning_of_month
    @month_end = @date.end_of_month
    @trend_start = @date - (TREND_DAYS - 1)

    daily = daily_volumes(
      [@month_start, @week_start, @trend_start].min,
      [@month_end, @week_end, @date].max
    )

    @people = build_people(daily)
    @totals = %i[day week month].index_with { |period| @people.sum { |p| p[period][:liters] }.round(1) }
    @delivery_counts = %i[day week month].index_with { |period| @people.sum { |p| p[period][:deliveries] } }
    @trend_dates = (@trend_start..@date).to_a
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
        trend: (@trend_start..@date).map { |d| days.key?(d) ? days[d][:liters].round(1) : 0 }
      }
    end

    entries.sort_by { |e| [-e[:month][:liters], -e[:week][:liters], e[:name].downcase] }
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

    ranked = @people.select { |p| p[:month][:liters].positive? || p[:week][:liters].positive? || p[:day][:liters].positive? }.first(15)
    {
      trend: { labels: @trend_dates.map { |d| d.strftime('%-d %b') }, series: series },
      ranking: {
        labels: ranked.map { |p| p[:name] },
        day: ranked.map { |p| p[:day][:liters] },
        week: ranked.map { |p| p[:week][:liters] },
        month: ranked.map { |p| p[:month][:liters] }
      }
    }
  end

  def parse_date(value)
    value.present? ? Date.iso8601(value) : Date.current
  rescue ArgumentError
    Date.current
  end

  def check_sidebar_permission
    return if current_user&.has_sidebar_permission?('subscriptions')

    redirect_to admin_dashboard_path, alert: 'You do not have permission to access this page.'
  end
end
