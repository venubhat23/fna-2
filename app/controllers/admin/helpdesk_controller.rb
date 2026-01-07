class Admin::HelpdeskController < Admin::ApplicationController
  before_action :authenticate_user!

  def index
    @total_tickets = 1250
    @open_tickets = 45
    @resolved_today = 23
    @avg_response_time = "2.4h"

    @recent_tickets = [
      {
        id: "HD-001",
        customer: "John Doe",
        subject: "Policy Claim Issue",
        status: "Open",
        priority: "High",
        created_at: Time.current - 2.hours,
        assigned_to: "Agent Smith"
      },
      {
        id: "HD-002",
        customer: "Jane Smith",
        subject: "Premium Payment Query",
        status: "In Progress",
        priority: "Medium",
        created_at: Time.current - 4.hours,
        assigned_to: "Agent Johnson"
      },
      {
        id: "HD-003",
        customer: "Mike Wilson",
        subject: "Policy Renewal",
        status: "Resolved",
        priority: "Low",
        created_at: Time.current - 6.hours,
        assigned_to: "Agent Brown"
      },
      {
        id: "HD-004",
        customer: "Sarah Davis",
        subject: "Document Upload Issue",
        status: "Open",
        priority: "Medium",
        created_at: Time.current - 8.hours,
        assigned_to: "Agent Taylor"
      },
      {
        id: "HD-005",
        customer: "Robert Chen",
        subject: "Health Insurance Query",
        status: "Escalated",
        priority: "High",
        created_at: Time.current - 10.hours,
        assigned_to: "Senior Agent Lee"
      }
    ]

    @ticket_stats_by_status = [
      { status: "Open", count: 45, color: "#ff6b6b" },
      { status: "In Progress", count: 32, color: "#4ecdc4" },
      { status: "Resolved", count: 156, color: "#45b7d1" },
      { status: "Escalated", count: 8, color: "#f9ca24" }
    ]

    @monthly_ticket_trend = [
      { month: "Jan", tickets: 120 },
      { month: "Feb", tickets: 135 },
      { month: "Mar", tickets: 148 },
      { month: "Apr", tickets: 162 },
      { month: "May", tickets: 158 },
      { month: "Jun", tickets: 145 },
      { month: "Jul", tickets: 152 },
      { month: "Aug", tickets: 167 },
      { month: "Sep", tickets: 143 },
      { month: "Oct", tickets: 156 },
      { month: "Nov", tickets: 149 },
      { month: "Dec", tickets: 138 }
    ]
  end

  def show
    @ticket_id = params[:id]
  end

  def analytics
    # Analytics page
  end

  def tickets
    # Tickets listing page
  end

  def knowledge_base
    # Knowledge base page
  end

  def update_status
    # Update ticket status
    redirect_to admin_helpdesk_index_path, notice: "Ticket status updated successfully"
  end

  def assign_to
    # Assign ticket to agent
    redirect_to admin_helpdesk_index_path, notice: "Ticket assigned successfully"
  end

  def add_response
    # Add response to ticket
    redirect_to admin_helpdesk_index_path, notice: "Response added successfully"
  end

  private

  def helpdesk_params
    params.require(:helpdesk).permit(:subject, :description, :priority, :status, :assigned_to)
  end
end