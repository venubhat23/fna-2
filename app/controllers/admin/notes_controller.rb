class Admin::NotesController < ApplicationController
  before_action :set_note, only: [:show, :edit, :update, :destroy]

  def index
    @notes = Note.includes(:created_by_user).recent

    # Apply filters
    @notes = @notes.by_status(params[:status]) if params[:status].present?
    @notes = @notes.by_payment_method(params[:payment_method]) if params[:payment_method].present?
    @notes = @notes.by_paid_from(params[:paid_from]) if params[:paid_from].present?
    @notes = @notes.by_paid_to_category(params[:paid_to_category]) if params[:paid_to_category].present?

    # Date range filter
    if params[:start_date].present? && params[:end_date].present?
      @notes = @notes.by_date_range(Date.parse(params[:start_date]), Date.parse(params[:end_date]))
    end

    # Month/year filter
    if params[:filter_month].present? && params[:filter_year].present?
      @notes = @notes.where(
        "EXTRACT(MONTH FROM note_date) = ? AND EXTRACT(YEAR FROM note_date) = ?",
        params[:filter_month].to_i, params[:filter_year].to_i
      )
    elsif params[:filter_month].present?
      @notes = @notes.where("EXTRACT(MONTH FROM note_date) = ?", params[:filter_month].to_i)
    elsif params[:filter_year].present?
      @notes = @notes.where("EXTRACT(YEAR FROM note_date) = ?", params[:filter_year].to_i)
    end

    # Search filter
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @notes = @notes.where("title ILIKE ? OR paid_to ILIKE ? OR reference_number ILIKE ?",
                           search_term, search_term, search_term)
    end

    @notes = @notes.page(params[:page]).per(20)

    # Calculate statistics
    @stats = calculate_note_stats
  end

  def show
  end

  def new
    @note = Note.new
  end

  def create
    @note = Note.new(note_params)
    @note.created_by_user = current_user

    if @note.save
      redirect_to admin_notes_path, notice: 'Note created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @note.update(note_params)
      redirect_to admin_notes_path, notice: 'Note updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @note.destroy
    redirect_to admin_notes_path, notice: 'Note deleted successfully.'
  end

  private

  def set_note
    @note = Note.find(params[:id])
  end

  def note_params
    params.require(:note).permit(:title, :paid_to, :amount, :payment_method,
                                 :reference_number, :description, :status, :note_date,
                                 :paid_from, :paid_to_category)
  end

  def calculate_note_stats
    all_notes = Note.all

    {
      total_notes: all_notes.count,
      total_amount: all_notes.sum(:amount),
      pending_count: all_notes.where(status: 'pending').count,
      completed_count: all_notes.where(status: 'completed').count,
      cancelled_count: all_notes.where(status: 'cancelled').count,
      pending_amount: all_notes.where(status: 'pending').sum(:amount),
      completed_amount: all_notes.where(status: 'completed').sum(:amount)
    }
  end
end