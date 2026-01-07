class Admin::SubAgentDocumentsController < Admin::ApplicationController
  before_action :set_sub_agent
  before_action :set_sub_agent_document, only: [:show, :edit, :update, :destroy]

  # DELETE /admin/sub_agents/:sub_agent_id/sub_agent_documents/:id
  def destroy
    @sub_agent_document.destroy
    redirect_to edit_admin_sub_agent_path(@sub_agent), notice: 'Document was successfully deleted.'
  end

  # POST /admin/sub_agents/:sub_agent_id/sub_agent_documents
  def create
    @sub_agent_document = @sub_agent.sub_agent_documents.build(sub_agent_document_params)

    if @sub_agent_document.save
      redirect_to edit_admin_sub_agent_path(@sub_agent), notice: 'Document was successfully uploaded.'
    else
      redirect_to edit_admin_sub_agent_path(@sub_agent), alert: 'Failed to upload document.'
    end
  end

  # PATCH/PUT /admin/sub_agents/:sub_agent_id/sub_agent_documents/:id
  def update
    if @sub_agent_document.update(sub_agent_document_params)
      redirect_to edit_admin_sub_agent_path(@sub_agent), notice: 'Document was successfully updated.'
    else
      redirect_to edit_admin_sub_agent_path(@sub_agent), alert: 'Failed to update document.'
    end
  end

  # GET /admin/sub_agents/:sub_agent_id/sub_agent_documents/new
  def new
    @sub_agent_document = @sub_agent.sub_agent_documents.build
  end

  # GET /admin/sub_agents/:sub_agent_id/sub_agent_documents/:id/edit
  def edit
  end

  private

  def set_sub_agent
    @sub_agent = SubAgent.find(params[:sub_agent_id])
  end

  def set_sub_agent_document
    @sub_agent_document = @sub_agent.sub_agent_documents.find(params[:id])
  end

  def sub_agent_document_params
    params.require(:sub_agent_document).permit(:document_type, :document_file)
  end
end