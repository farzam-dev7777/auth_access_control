class CreateActivityLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :activity_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.string :action, null: false
      t.jsonb :metadata, default: {}
      t.string :ip_address
      t.string :user_agent
      t.datetime :performed_at, null: false

      t.timestamps
    end

    add_index :activity_logs, [:organization_id, :action]
    add_index :activity_logs, [:organization_id, :performed_at]
    add_index :activity_logs, [:user_id, :performed_at]
  end
end