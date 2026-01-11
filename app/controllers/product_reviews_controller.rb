class ProductReviewsController < ApplicationController
  before_action :set_product, only: [:create]
  before_action :set_review, only: [:update, :destroy, :mark_helpful, :show]

  def create
    @review = @product.product_reviews.build(review_params)

    # Set current user/customer if logged in
    if current_user.present?
      @review.user = current_user
    elsif current_customer.present?
      @review.customer = current_customer
    end

    if @review.save
      render json: {
        success: true,
        message: 'Review submitted successfully! It will be reviewed before publishing.',
        review: review_json(@review)
      }
    else
      render json: {
        success: false,
        errors: @review.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def show
    render json: review_json(@review)
  end

  def update
    if @review.update(review_params)
      render json: {
        success: true,
        message: 'Review updated successfully!',
        review: review_json(@review)
      }
    else
      render json: {
        success: false,
        errors: @review.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    # Only allow deletion by the review author or admin
    if can_delete_review?
      @review.destroy
      render json: { success: true, message: 'Review deleted successfully!' }
    else
      render json: { success: false, message: 'You are not authorized to delete this review.' }, status: :forbidden
    end
  end

  def mark_helpful
    # Simple helpful marking (could be enhanced with user tracking)
    @review.increment!(:helpful_count)
    render json: {
      success: true,
      helpful_count: @review.helpful_count,
      message: 'Thank you for marking this review as helpful!'
    }
  end

  private

  def set_product
    @product = Product.find(params[:product_id])
  end

  def set_review
    @review = ProductReview.find(params[:id])
  end

  def review_params
    params.require(:product_review).permit(
      :rating, :comment, :title, :pros, :cons,
      :reviewer_name, :reviewer_email
    )
  end

  def review_json(review)
    {
      id: review.id,
      rating: review.rating,
      title: review.title,
      comment: review.comment,
      pros: review.pros,
      cons: review.cons,
      reviewer_name: review.reviewer_display_name,
      verified_purchase: review.verified_purchase?,
      helpful_count: review.helpful_count,
      created_at: review.created_at.strftime("%B %d, %Y"),
      star_display: review.star_display,
      time_ago: time_ago_in_words(review.created_at)
    }
  end

  def can_delete_review?
    return true if current_user&.admin?
    return true if current_user.present? && @review.user_id == current_user.id
    return true if current_customer.present? && @review.customer_id == current_customer.id
    false
  end

  def current_customer
    # Implement your customer authentication logic here
    # This depends on how you handle customer sessions
    nil
  end
end
