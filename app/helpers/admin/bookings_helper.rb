module Admin::BookingsHelper
  BOOKING_SOURCES = {
    'mobile_api'       => { label: 'Mobile App',      icon: 'bi-phone',         css: 'source-mobile' },
    'customer'         => { label: 'Website',         icon: 'bi-globe',         css: 'source-customer' },
    'franchise'        => { label: 'Franchise',       icon: 'bi-shop',          css: 'source-franchise' },
    'affiliate'        => { label: 'Affiliate',       icon: 'bi-person-badge',  css: 'source-affiliate' },
    'delivery_person'  => { label: 'Delivery Person', icon: 'bi-person-badge',  css: 'source-delivery' }
  }.freeze

  DEFAULT_BOOKING_SOURCE = { label: 'Store', icon: 'bi-person-gear', css: 'source-store' }.freeze

  BOOKING_SOURCE_FILTER_OPTIONS = [
    ['All Sources', ''],
    ['Customer Website', 'customer'],
    ['Mobile App', 'mobile_api'],
    ['Franchise', 'franchise'],
    ['Store / Admin', 'admin'],
    ['Affiliate', 'affiliate'],
    ['Delivery Person', 'delivery_person']
  ].freeze

  def booking_source(booking)
    BOOKING_SOURCES.fetch(booking.booked_by, DEFAULT_BOOKING_SOURCE)
  end

  def booking_source_badge(booking)
    source = booking_source(booking)
    content_tag(:span, class: "badge source-badge #{source[:css]}") do
      concat content_tag(:i, nil, class: "#{source[:icon]} me-1")
      concat source[:label]
    end
  end
end
