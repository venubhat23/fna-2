class Admin::StoresController < Admin::ApplicationController
  before_action :authenticate_user!
  before_action :set_store, only: [:show, :edit, :update, :destroy, :toggle_status]

  def index
    @stores = Store.all.order(created_at: :desc)
  end

  def show
  end

  def new
    @store = Store.new
  end

  def create
    @store = Store.new(store_params)

    if @store.save
      redirect_to admin_stores_path, notice: 'Store was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @store.update(store_params)
      redirect_to admin_stores_path, notice: 'Store was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @store.destroy
    redirect_to admin_stores_path, notice: 'Store was successfully deleted.'
  end

  def toggle_status
    @store.update(status: !@store.status)
    redirect_to admin_stores_path, notice: "Store status updated."
  end

  private

  def set_store
    @store = Store.find(params[:id])
  end

  def store_params
    params.require(:store).permit(:name, :description, :address, :city, :state,
                                   :pincode, :contact_person, :contact_mobile, :status)
  end
end