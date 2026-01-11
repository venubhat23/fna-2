class ProductRating < ApplicationRecord
  belongs_to :product
  belongs_to :customer, optional: true
  belongs_to :user, optional: true

  validates :rating, presence: true, inclusion: { in: 1..5, message: 'must be between 1 and 5' }
  validates :comment, length: { maximum: 1000 }
  validates :reviewer_name, presence: true, if: -> { customer.blank? && user.blank? }
  validates :reviewer_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  # Ensure one rating per customer/user per product
  validates :customer_id, uniqueness: { scope: :product_id }, if: -> { customer.present? }
  validates :user_id, uniqueness: { scope: :product_id }, if: -> { user.present? && customer.blank? }

  enum :status, { pending: 0, approved: 1, rejected: 2, spam: 3 }

  scope :approved, -> { where(status: :approved) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_rating, ->(rating) { where(rating: rating) }

  before_validation :set_reviewer_info

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

  private

  def set_reviewer_info
    if customer.present?
      self.reviewer_name = customer.display_name
      self.reviewer_email = customer.email
    elsif user.present?
      self.reviewer_name = user.display_name
      self.reviewer_email = user.email
    end
  end
end
