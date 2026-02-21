class Admin::MilkDeliveryTasksController < Admin::ApplicationController
  before_action :set_task, only: [:update, :destroy, :complete, :cancel, :pause, :resume]

  # Individual Task Actions

  def update
    if @task.update(task_params)
      render json: {
        success: true,
        message: 'Task updated successfully',
        task: task_json(@task)
      }
    else
      render json: {
        success: false,
        errors: @task.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    if @task.destroy
      render json: {
        success: true,
        message: 'Task deleted successfully'
      }
    else
      render json: {
        success: false,
        message: 'Failed to delete task'
      }, status: :unprocessable_entity
    end
  end

  def complete
    if @task.update(status: 'completed', completed_at: Time.current)
      render json: {
        success: true,
        message: 'Task marked as completed',
        task: task_json(@task)
      }
    else
      render json: {
        success: false,
        message: 'Failed to complete task'
      }, status: :unprocessable_entity
    end
  end

  def cancel
    if @task.update(status: 'cancelled')
      render json: {
        success: true,
        message: 'Task cancelled successfully',
        task: task_json(@task)
      }
    else
      render json: {
        success: false,
        message: 'Failed to cancel task'
      }, status: :unprocessable_entity
    end
  end

  def pause
    if @task.pause!
      render json: {
        success: true,
        message: 'Task paused successfully',
        task: task_json(@task)
      }
    else
      render json: {
        success: false,
        message: 'Failed to pause task'
      }, status: :unprocessable_entity
    end
  end

  def resume
    if @task.resume!
      render json: {
        success: true,
        message: 'Task resumed successfully',
        task: task_json(@task)
      }
    else
      render json: {
        success: false,
        message: 'Failed to resume task'
      }, status: :unprocessable_entity
    end
  end

  # Bulk Actions

  def bulk_update
    task_ids = params[:task_ids] || []
    update_params = params.require(:task).permit(:quantity, :delivery_date, :delivery_person_id)

    if task_ids.empty?
      render json: {
        success: false,
        message: 'No tasks selected'
      }, status: :unprocessable_entity
      return
    end

    tasks = MilkDeliveryTask.where(id: task_ids)
    updated_count = 0
    failed_tasks = []

    tasks.each do |task|
      if task.update(update_params)
        updated_count += 1
      else
        failed_tasks << { id: task.id, errors: task.errors.full_messages }
      end
    end

    if failed_tasks.empty?
      render json: {
        success: true,
        message: "#{updated_count} tasks updated successfully",
        updated_count: updated_count
      }
    else
      render json: {
        success: false,
        message: "#{updated_count} tasks updated, #{failed_tasks.length} failed",
        updated_count: updated_count,
        failed_tasks: failed_tasks
      }, status: :unprocessable_entity
    end
  end

  def bulk_complete
    task_ids = params[:task_ids] || []

    if task_ids.empty?
      render json: {
        success: false,
        message: 'No tasks selected'
      }, status: :unprocessable_entity
      return
    end

    tasks = MilkDeliveryTask.where(id: task_ids, status: ['pending', 'assigned'])
    completed_count = tasks.update_all(
      status: 'completed',
      completed_at: Time.current
    )

    render json: {
      success: true,
      message: "#{completed_count} tasks marked as completed",
      completed_count: completed_count
    }
  end

  def bulk_delete
    task_ids = params[:task_ids] || []

    if task_ids.empty?
      render json: {
        success: false,
        message: 'No tasks selected'
      }, status: :unprocessable_entity
      return
    end

    deleted_count = MilkDeliveryTask.where(id: task_ids).destroy_all.length

    render json: {
      success: true,
      message: "#{deleted_count} tasks deleted successfully",
      deleted_count: deleted_count
    }
  end

  def bulk_cancel
    task_ids = params[:task_ids] || []

    if task_ids.empty?
      render json: {
        success: false,
        message: 'No tasks selected'
      }, status: :unprocessable_entity
      return
    end

    cancelled_count = MilkDeliveryTask.where(id: task_ids).update_all(status: 'cancelled')

    render json: {
      success: true,
      message: "#{cancelled_count} tasks cancelled",
      cancelled_count: cancelled_count
    }
  end

  private

  def set_task
    @task = MilkDeliveryTask.find_by(id: params[:id])
    unless @task
      render json: {
        success: false,
        message: 'Task not found'
      }, status: :not_found
    end
  end

  def task_params
    params.require(:task).permit(:quantity, :delivery_date, :status, :delivery_person_id, :unit)
  end

  def task_json(task)
    {
      id: task.id,
      delivery_date: task.delivery_date.strftime('%Y-%m-%d'),
      quantity: task.quantity,
      unit: task.unit,
      status: task.status,
      completed_at: task.completed_at,
      delivery_person: task.delivery_person ? {
        id: task.delivery_person.id,
        name: "#{task.delivery_person.first_name} #{task.delivery_person.last_name}".strip
      } : nil
    }
  end
end