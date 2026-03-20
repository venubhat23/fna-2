class CreateImportProgresses < ActiveRecord::Migration[8.0]
  def change
    create_table :import_progresses do |t|
      t.string :job_id, null: false
      t.integer :total_items, null: false, default: 0
      t.integer :processed_items, null: false, default: 0
      t.string :status, null: false, default: 'started'
      t.text :message
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :import_progresses, :job_id, unique: true
    add_index :import_progresses, :status
  end
end
