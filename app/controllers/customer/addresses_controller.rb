class Customer::AddressesController < Customer::BaseController
  before_action :find_address, only: [:show, :edit, :update, :destroy]

  def index
    @addresses = current_customer.customer_addresses.order(:is_default, :created_at)
  end

  def show
  end

  def new
    @address = current_customer.customer_addresses.build
  end

  def create
    @address = current_customer.customer_addresses.build(address_params)

    # If this is set as default, make others non-default
    if @address.is_default?
      current_customer.customer_addresses.update_all(is_default: false)
    elsif current_customer.customer_addresses.empty?
      # First address should be default
      @address.is_default = true
    end

    if @address.save
      redirect_to customer_addresses_path, notice: 'Address added successfully!'
    else
      render :new
    end
  end

  def edit
  end

  def update
    # If this is set as default, make others non-default
    if address_params[:is_default] == '1' || address_params[:is_default] == true
      current_customer.customer_addresses.where.not(id: @address.id).update_all(is_default: false)
    end

    if @address.update(address_params)
      redirect_to customer_addresses_path, notice: 'Address updated successfully!'
    else
      render :edit
    end
  end

  def destroy
    was_default = @address.is_default?
    @address.destroy

    # If deleted address was default, make another address default
    if was_default && current_customer.customer_addresses.any?
      current_customer.customer_addresses.first.update(is_default: true)
    end

    redirect_to customer_addresses_path, notice: 'Address deleted successfully!'
  end

  private

  def find_address
    @address = current_customer.customer_addresses.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to customer_addresses_path, alert: 'Address not found.'
  end

  def address_params
    params.require(:customer_address).permit(
      :name, :mobile, :address_type, :address, :landmark,
      :city, :state, :pincode, :latitude, :longitude, :is_default
    )
  end
end