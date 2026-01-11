class DeliveryRule < ApplicationRecord
  belongs_to :product

  validates :rule_type, presence: true
  validates :location_data, presence: true, unless: -> { rule_type == 'everywhere' || rule_type == 0 }
  validates :delivery_days, numericality: { greater_than: 0 }, allow_blank: true
  validates :delivery_charge, numericality: { greater_than_or_equal_to: 0 }

  validate :location_data_format

  enum :rule_type, { everywhere: 0, state: 1, city: 2, pincode: 3 }

  # Set default values
  after_initialize :set_defaults

  def set_defaults
    self.rule_type ||= 'everywhere'
    self.delivery_days ||= 7
    self.delivery_charge ||= 0.0
    self.location_data ||= '[]'
  end

  scope :for_rule_type, ->(type) { where(rule_type: type) }
  scope :included_rules, -> { where(is_excluded: false) }
  scope :excluded_rules, -> { where(is_excluded: true) }

  def location_list
    return [] if everywhere? || location_data.blank?

    begin
      JSON.parse(location_data)
    rescue JSON::ParserError
      []
    end
  end

  def location_list=(list)
    self.location_data = list.is_a?(Array) ? list.to_json : list
  end

  def formatted_locations
    if everywhere?
      'All locations'
    elsif state? || city? || pincode?
      location_list.join(', ')
    else
      'Unknown'
    end
  end

  def rule_description
    base = is_excluded? ? "Exclude from" : "Include for"

    if everywhere?
      is_excluded? ? "Exclude from all locations" : "Available for all locations"
    elsif state?
      "#{base} states: #{formatted_locations}"
    elsif city?
      "#{base} cities: #{formatted_locations}"
    elsif pincode?
      "#{base} pincodes: #{formatted_locations}"
    end
  end

  def delivery_info
    info = []
    info << "#{delivery_days} days" if delivery_days.present?
    info << "₹#{delivery_charge}" if delivery_charge > 0
    info.join(', ')
  end

  private

  def location_data_format
    return if rule_type == 'everywhere' || rule_type == 0

    if location_data.blank?
      errors.add(:location_data, "can't be blank for #{rule_type} rules")
      return
    end

    begin
      parsed_data = JSON.parse(location_data)
      unless parsed_data.is_a?(Array) && parsed_data.all? { |item| item.is_a?(String) }
        errors.add(:location_data, 'must be a valid JSON array of strings')
      end
    rescue JSON::ParserError
      errors.add(:location_data, 'must be valid JSON')
    end
  end
end