class Category < ApplicationRecord
  has_many :products, dependent: :destroy

  has_one_attached :image

  # In-process cache, not Rails.cache: Rails.cache is Solid Cache in this app, which stores
  # entries in the same remote Postgres database (see database.yml), so fetching through it
  # would just trade one network round trip for another. The active-category list is read on
  # nearly every storefront page load and rarely changes, so a real in-memory cache is what
  # actually avoids the round trip. Same pattern as SystemSetting::LOCAL_CACHE.
  LOCAL_CACHE = ActiveSupport::Cache::MemoryStore.new

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :display_order, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Store image URL as backup when image is attached
  after_commit :backup_image_url, if: :saved_change_to_id?
  after_commit :clear_active_categories_cache

  scope :active, -> { where(status: true) }
  scope :inactive, -> { where(status: false) }
  scope :ordered, -> { order(:display_order, :name) }

  before_validation :set_default_display_order, if: :new_record?

  def active?
    status?
  end

  def inactive?
    !status?
  end

  def products_count
    products.size
  end

  def self.for_select
    ordered.pluck(:name, :id)
  end

  # Cached: same result set as where(status: true).order(:display_order, :name), just
  # served from the in-process cache instead of a fresh query on every request.
  def self.active_ordered_by_display
    LOCAL_CACHE.fetch('category_active_by_display_order', expires_in: 10.minutes) do
      where(status: true).order(:display_order, :name).to_a
    end
  end

  # Cached: same result set as where(status: true).order(:name).
  def self.active_ordered_by_name
    LOCAL_CACHE.fetch('category_active_by_name', expires_in: 10.minutes) do
      where(status: true).order(:name).to_a
    end
  end

  def display_image_url
    if image.attached?
      Rails.application.routes.url_helpers.rails_blob_url(image, only_path: true)
    else
      # Return a default category image URL
      "/assets/category-placeholder.png"
    end
  end

  def has_image?
    image.attached?
  end

  private

  def set_default_display_order
    max_order = Category.maximum(:display_order) || 0
    self.display_order ||= max_order + 1
  end

  def backup_image_url
    if image.attached?
      update_column(:image_backup_url, display_image_url)
    end
  rescue => e
    Rails.logger.error "Failed to backup image URL for category #{id}: #{e.message}"
  end

  def clear_active_categories_cache
    LOCAL_CACHE.clear
  end
end