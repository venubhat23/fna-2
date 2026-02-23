class Banner < ApplicationRecord
  # Image attachment
  has_one_attached :banner_image

  # Validations
  validates :title, presence: true, length: { maximum: 255 }
  validates :description, length: { maximum: 500 }
  validates :display_start_date, :display_end_date, :display_location, presence: true
  validates :display_location, inclusion: { in: ['dashboard', 'login', 'home', 'sidebar'] }
  validates :status, inclusion: { in: [true, false] }
  validates :display_order, presence: true, numericality: { greater_than_or_equal_to: 0 }
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

  def end_date_after_start_date
    return unless display_start_date && display_end_date

    if display_end_date < display_start_date
      errors.add(:display_end_date, 'must be after start date')
    end
  end
end
