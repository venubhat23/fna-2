class Affiliate::ReferralsController < Affiliate::ApplicationController
  before_action :set_referral, only: [:show, :update, :destroy, :mark_registered, :mark_converted]

  # GET /affiliate/referrals
  def index
    @referrals = current_affiliate.referrals
      .includes(:customer)
      .order(created_at: :desc)
      .page(params[:page]).per(20)

    # Filter by status if specified
    if params[:status].present?
      @referrals = @referrals.where(status: params[:status])
    end

    @stats = {
      total: current_affiliate.total_referrals,
      pending: current_affiliate.pending_referrals,
      registered: current_affiliate.registered_referrals,
      converted: current_affiliate.converted_referrals,
      conversion_rate: current_affiliate.conversion_rate
    }
  end

  # GET /affiliate/referrals/new
  def new
    @referral = current_affiliate.referrals.build
  end

  # POST /affiliate/referrals
  def create
    @referral = current_affiliate.referrals.build(referral_params)

    if @referral.save
      redirect_to affiliate_referrals_path, notice: 'Referral added successfully!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /affiliate/referrals/1
  def show
  end

  # PATCH/PUT /affiliate/referrals/1
  def update
    if @referral.update(referral_params.except(:referred_email, :referred_mobile))
      redirect_to affiliate_referral_path(@referral), notice: 'Referral updated successfully!'
    else
      render :show, status: :unprocessable_entity
    end
  end

  # DELETE /affiliate/referrals/1
  def destroy
    @referral.destroy
    redirect_to affiliate_referrals_path, notice: 'Referral deleted successfully!'
  end

  # PATCH /affiliate/referrals/1/mark_registered
  def mark_registered
    if @referral.status == 'pending'
      @referral.update!(status: 'registered', notes: (@referral.notes.to_s + " | Marked as registered on #{Date.current}").strip)
      redirect_to affiliate_referrals_path, notice: 'Referral marked as registered!'
    else
      redirect_to affiliate_referrals_path, alert: 'Only pending referrals can be marked as registered.'
    end
  end

  # PATCH /affiliate/referrals/1/mark_converted
  def mark_converted
    if @referral.status == 'registered'
      @referral.mark_as_converted!
      redirect_to affiliate_referrals_path, notice: 'Referral marked as converted! Congratulations!'
    else
      redirect_to affiliate_referrals_path, alert: 'Only registered referrals can be marked as converted.'
    end
  end

  private

  def set_referral
    @referral = current_affiliate.referrals.find(params[:id])
  end

  def referral_params
    params.require(:referral).permit(:referred_name, :referred_mobile, :referred_email, :notes)
  end
end