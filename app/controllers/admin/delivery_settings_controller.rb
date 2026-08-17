class Admin::DeliverySettingsController < Admin::ApplicationController
  before_action :authenticate_user!
  before_action :set_delivery_charge, only: [:edit, :update]

  def index
    load_delivery_charges_index_data
  end

  def new
    @delivery_charge = DeliveryCharge.new
  end

  def create
    @delivery_charge = DeliveryCharge.new(delivery_charge_params)

    respond_to do |format|
      if @delivery_charge.save
        format.html { redirect_to admin_delivery_settings_path, notice: 'Delivery charge created successfully.' }
        format.json { render json: { success: true, message: 'Delivery charge created successfully' } }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { success: false, message: 'Failed to create delivery charge', errors: @delivery_charge.errors.full_messages } }
      end
    end
  end

  def update
    if @delivery_charge.update(delivery_charge_params)
      respond_to do |format|
        format.html { redirect_to admin_delivery_settings_path, notice: 'Delivery charge updated successfully.', status: :see_other }
        format.json { render json: { success: true, message: 'Delivery charge updated successfully' } }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { success: false, message: 'Failed to update delivery charge', errors: @delivery_charge.errors.full_messages } }
      end
    end
  end

  def edit
    # @delivery_charge set by before_action
  end

  def edit_pincode_charges
    load_delivery_charges_index_data
    render :index
  end

  def update_pincode_charges
    success_count = 0
    error_messages = []

    submitted = params[:delivery_charges] || {}
    existing_by_pincode = DeliveryCharge.where(pincode: submitted.keys).index_by(&:pincode)

    submitted.each do |pincode, charge_params|
      delivery_charge = existing_by_pincode[pincode] || DeliveryCharge.new(pincode: pincode)
      delivery_charge.assign_attributes(charge_params.permit(:charge_amount, :is_active))

      if delivery_charge.save
        success_count += 1
      else
        error_messages << "Failed to update #{pincode}: #{delivery_charge.errors.full_messages.join(', ')}"
      end
    end

    if error_messages.empty?
      render json: {
        success: true,
        message: "Successfully updated #{success_count} delivery charges"
      }
    else
      render json: {
        success: false,
        message: "Updated #{success_count} charges with #{error_messages.count} errors",
        errors: error_messages
      }
    end
  end

  private

  # Shared by #index and #edit_pincode_charges (both render the same view).
  def load_delivery_charges_index_data
    scope = DeliveryCharge.order(:pincode)
    @delivery_charges = scope.respond_to?(:page) ? scope.page(params[:page]).per(20) : scope
    @delivery_charges.load_async if @delivery_charges.respond_to?(:load_async)

    total, active, inactive, avg_active_charge = DeliveryCharge.pick(
      Arel.sql('COUNT(*), COUNT(*) FILTER (WHERE is_active), COUNT(*) FILTER (WHERE NOT is_active), AVG(charge_amount) FILTER (WHERE is_active)')
    )
    @pincode_stats = {
      total: total.to_i,
      active: active.to_i,
      inactive: inactive.to_i,
      avg_active_charge: avg_active_charge ? avg_active_charge.to_f.round(2) : 0
    }

    # Both come from the same unfiltered DeliveryCharge scope, so reuse the
    # total here instead of a second COUNT(*) round trip for Kaminari.
    @delivery_charges.instance_variable_set(:@total_count, @pincode_stats[:total]) if @delivery_charges.respond_to?(:page)
  end

  def set_delivery_charge
    @delivery_charge = DeliveryCharge.find(params[:id])
  end

  def delivery_charge_params
    params.require(:delivery_charge).permit(:pincode, :area, :charge_amount, :is_active,
                                            :free_delivery_allowed, :min_order_for_free_delivery)
  end
end
