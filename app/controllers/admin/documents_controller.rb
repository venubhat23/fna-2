class Admin::DocumentsController < Admin::ApplicationController
  before_action :set_document, only: [:show, :edit, :update, :destroy, :download]
  before_action :set_documentable, only: [:index, :new, :create]

  # GET /admin/documents or /admin/users/1/documents
  def index
    if @documentable
      @documents = @documentable.uploaded_documents.recent.page(params[:page]).per(10)
      @page_title = "Documents for #{@documentable.class.name} ##{@documentable.id}"
    else
      @documents = Document.includes(:documentable).recent.page(params[:page]).per(20)
      @page_title = "All Documents"
    end

    # Filter by document type if provided
    @documents = @documents.by_type(params[:document_type]) if params[:document_type].present?

    # Statistics
    @total_documents = @documentable ? @documentable.uploaded_documents.count : Document.count
    @document_types_count = (@documentable ? @documentable.uploaded_documents : Document).group(:document_type).count
  end

  # GET /admin/documents/1
  def show
    @related_documents = @document.documentable.uploaded_documents.where.not(id: @document.id).limit(5)
  end

  # GET /admin/documents/new or /admin/users/1/documents/new
  def new
    if @documentable
      @document = @documentable.uploaded_documents.build
    else
      @document = Document.new
    end
  end

  # GET /admin/documents/1/edit
  def edit
  end

  # POST /admin/documents or /admin/users/1/documents
  def create
    if @documentable
      @document = @documentable.uploaded_documents.build(document_params)
      @document.uploaded_by = current_user_name
      redirect_path = polymorphic_path([:admin, @documentable, :documents])
    else
      @document = Document.new(document_params)
      @document.uploaded_by = current_user_name
      redirect_path = admin_documents_path
    end

    if @document.save
      redirect_to redirect_path, notice: 'Document was successfully uploaded.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /admin/documents/1
  def update
    if @document.update(document_params.except(:file))
      redirect_to admin_document_path(@document), notice: 'Document was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /admin/documents/1
  def destroy
    documentable = @document.documentable
    @document.destroy!

    if documentable && params[:return_to_record] == 'true'
      redirect_to polymorphic_path([:admin, documentable, :documents]), notice: 'Document was successfully deleted.'
    else
      redirect_to admin_documents_path, notice: 'Document was successfully deleted.'
    end
  rescue ActiveRecord::RecordNotDestroyed => e
    redirect_to admin_documents_path, alert: "Failed to delete document: #{e.message}"
  end

  # GET /admin/documents/1/download
  def download
    if @document.file.attached?
      redirect_to rails_blob_path(@document.file, disposition: "attachment")
    else
      redirect_to admin_documents_path, alert: 'File not found.'
    end
  end

  private

  def set_document
    @document = Document.find(params[:id])
  end

  def set_documentable
    # Support nested routes like /admin/users/1/documents
    if params[:user_id]
      @documentable = User.find(params[:user_id])
    elsif params[:lead_id]
      @documentable = Lead.find(params[:lead_id])
    elsif params[:customer_id]
      @documentable = Customer.find(params[:customer_id])
    elsif params[:documentable_type] && params[:documentable_id]
      @documentable = params[:documentable_type].constantize.find(params[:documentable_id])
    end
  end

  def document_params
    params.require(:document).permit(:title, :description, :document_type, :file, :documentable_type, :documentable_id)
  end

  def current_user_name
    # You can customize this based on your user authentication system
    if respond_to?(:current_user) && current_user
      "#{current_user.first_name} #{current_user.last_name}".strip
    else
      'Admin User'
    end
  end
end