class Banner < ApplicationRecord
  # Image attachment
  has_one_attached :banner_image

  # In-process cache, not Rails.cache: Rails.cache is Solid Cache in this app, which stores
  # entries in the same remote Postgres database (see database.yml), so fetching through it
  # would just trade one network round trip for another. Same pattern as
  # Category::LOCAL_CACHE / SystemSetting::LOCAL_CACHE.
  LOCAL_CACHE = ActiveSupport::Cache::MemoryStore.new
  after_commit :clear_local_cache

  # Validations
  validates :title, length: { maximum: 255 }, allow_nil: true
  validates :description, length: { maximum: 500 }, allow_nil: true
  validates :display_location, inclusion: { in: ['dashboard', 'login', 'home', 'sidebar'] }, allow_nil: true
  validates :status, inclusion: { in: [true, false] }, allow_nil: true
  validates :display_order, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :redirect_link, format: { with: URI::regexp }, allow_blank: true

  # Custom validation for date range
  validate :end_date_after_start_date

  # Scopes
  scope :active, -> { where(status: true) }
  scope :inactive, -> { where(status: false) }
  scope :current, -> { where('display_start_date <= ? AND display_end_date >= ?', Date.current, Date.current) }
  scope :by_location, ->(location) { where(display_location: location) }
  scope :ordered, -> { order(:display_order, :created_at) }

  # Enums
  enum :display_location, { dashboard: 'dashboard', login: 'login', home: 'home', sidebar: 'sidebar' }

  # Instance methods
  def active?
    status && current?
  end

  def current?
    Date.current.between?(display_start_date, display_end_date)
  end

  def expired?
    display_end_date < Date.current
  end

  def upcoming?
    display_start_date > Date.current
  end

  def display_location_humanized
    display_location.humanize
  end

  # Cloudinary helper methods
  def cloudinary_image_url(transformation = {})
    return nil unless image_url.present?

    default_transformations = {
      width: 800,
      height: 400,
      crop: :fill,
      quality: :auto,
      fetch_format: :auto
    }

    Cloudinary::Utils.cloudinary_url(image_url, default_transformations.merge(transformation))
  end

  def cloudinary_thumbnail_url(width = 300, height = 150)
    return nil unless image_url.present?

    Cloudinary::Utils.cloudinary_url(image_url, {
      width: width,
      height: height,
      crop: :fill,
      quality: :auto,
      fetch_format: :auto
    })
  end

  def main_image_url
    if image_url.present?
      cloudinary_image_url
    elsif banner_image.attached?
      Rails.application.routes.url_helpers.rails_blob_url(banner_image, only_path: true)
    else
      nil
    end
  end

  def has_image?
    image_url.present? || banner_image.attached?
  end

  # Cached: same result set as the homepage-banner query in Customer::DashboardController,
  # served from the in-process cache instead of a fresh query on every request. Keyed by
  # date since the query filters on Date.current.
  def self.cached_homepage_banners
    LOCAL_CACHE.fetch("banner_homepage_#{Date.current}", expires_in: 10.minutes) do
      where(status: true, display_location: 'homepage')
        .where('display_start_date <= ? AND (display_end_date IS NULL OR display_end_date >= ?)',
               Date.current, Date.current)
        .order(:display_order).to_a
    end
  end

  def upload_to_cloudinary(file)
    begin
      result = Cloudinary::Uploader.upload(
        file,
        folder: 'banners',
        public_id: "banner-#{id}-#{SecureRandom.hex(8)}",
        overwrite: true,
        resource_type: :auto,
        transformation: [
          { width: 1200, height: 600, crop: :limit, quality: :auto, fetch_format: :auto }
        ]
      )

      update(image_url: result['public_id'])
      result
    rescue => e
      Rails.logger.error "Cloudinary upload failed for Banner #{id}: #{e.message}"
      false
    end
  end

  private

  def clear_local_cache
    LOCAL_CACHE.clear
  end

  def end_date_after_start_date
    return unless display_start_date && display_end_date

    if display_end_date < display_start_date
      errors.add(:display_end_date, 'must be after start date')
    end
  end
end
