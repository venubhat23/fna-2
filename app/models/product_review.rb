class ProductReview < ApplicationRecord
  belongs_to :product
  belongs_to :customer, optional: true
  belongs_to :user, optional: true

  validates :rating, presence: true, inclusion: { in: 1..5, message: 'must be between 1 and 5' }
  validates :comment, presence: true, length: { minimum: 10, maximum: 2000 }
  validates :title, length: { maximum: 200 }
  validates :reviewer_name, presence: true, if: -> { customer.blank? && user.blank? }
  validates :reviewer_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :pros, length: { maximum: 500 }
  validates :cons, length: { maximum: 500 }

  # Ensure one review per customer per product
  validates :customer_id, uniqueness: { scope: :product_id, message: 'has already reviewed this product' },
            if: -> { customer.present? }

  enum :status, { pending: 0, approved: 1, rejected: 2, spam: 3 }

  scope :approved, -> { where(status: :approved) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_rating, ->(rating) { where(rating: rating) }
  scope :helpful, -> { order(helpful_count: :desc) }

  before_validation :set_reviewer_info
  after_create :update_product_rating_cache

  def reviewer_display_name
    if customer.present?
      customer.display_name
    elsif user.present?
      user.display_name
    else
      reviewer_name || 'Anonymous'
    end
  end

  def verified_reviewer?
    customer.present? || user.present?
  end

  def star_display
    ('⭐' * rating) + ('☆' * (5 - rating))
  end

  def rating_percentage
    (rating.to_f / 5 * 100).round
  end

  def helpful?
    helpful_count > 0
  end

  def time_ago
    distance_of_time_in_words(created_at, Time.current) + ' ago'
  end

  def short_comment
    comment.truncate(150)
  end

  def has_pros_cons?
    pros.present? || cons.present?
  end

  def review_quality_score
    score = 0
    score += 1 if comment.length > 50
    score += 1 if title.present?
    score += 1 if has_pros_cons?
    score += 1 if verified_purchase?
    score += 1 if helpful_count > 0
    score
  end

  private

  def set_reviewer_info
    if customer.present?
      self.reviewer_name = customer.display_name
      self.reviewer_email = customer.email
      # Check if customer has actually purchased this product
      self.verified_purchase = customer.orders.joins(:order_items)
                                      .where(order_items: { product_id: product_id })
                                      .exists?
    elsif user.present?
      self.reviewer_name = user.display_name || "#{user.first_name} #{user.last_name}".strip
      self.reviewer_email = user.email
    end
  end

  def update_product_rating_cache
    # This could trigger a background job to update product rating cache
    product.touch # This will trigger any cache invalidation
  end
end
