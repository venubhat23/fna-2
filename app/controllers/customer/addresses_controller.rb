class Customer::AddressesController < Customer::BaseController
  before_action :find_address, only: [:show, :edit, :update, :destroy]

  def index
    @addresses = current_customer.customer_addresses.order(is_default: :desc, created_at: :desc)
    respond_to do |format|
      format.html
      format.json { render json: @addresses.map { |a| serialize_address(a) } }
    end
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

    respond_to do |format|
      if @address.save
        format.html { redirect_to customer_addresses_path, notice: 'Address added successfully!' }
        format.json { render json: serialize_address(@address), status: :created }
      else
        format.html { render :new }
        format.json { render json: { errors: @address.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    # If this is set as default, make others non-default
    if address_params[:is_default] == '1' || address_params[:is_default] == true
      current_customer.customer_addresses.where.not(id: @address.id).update_all(is_default: false)
    end

    respond_to do |format|
      if @address.update(address_params)
        format.html { redirect_to customer_addresses_path, notice: 'Address updated successfully!' }
        format.json { render json: serialize_address(@address) }
      else
        format.html { render :edit }
        format.json { render json: { errors: @address.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    was_default = @address.is_default?
    @address.destroy

    # If deleted address was default, make another address default
    if was_default && current_customer.customer_addresses.any?
      current_customer.customer_addresses.first.update(is_default: true)
    end

    respond_to do |format|
      format.html { redirect_to customer_addresses_path, notice: 'Address deleted successfully!' }
      format.json { head :no_content }
    end
  end

  private

  def find_address
    @address = current_customer.customer_addresses.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to customer_addresses_path, alert: 'Address not found.' }
      format.json { render json: { error: 'Address not found.' }, status: :not_found }
    end
  end

  def serialize_address(address)
    {
      id: address.id,
      name: address.name,
      mobile: address.mobile,
      address: address.address,
      address_type: address.address_type,
      landmark: address.landmark,
      city: address.city,
      state: address.state,
      pincode: address.pincode,
      is_default: address.is_default
    }
  end

  def address_params
    params.require(:customer_address).permit(
      :name, :mobile, :address_type, :address, :landmark,
      :city, :state, :pincode, :latitude, :longitude, :is_default
    )
  end
end