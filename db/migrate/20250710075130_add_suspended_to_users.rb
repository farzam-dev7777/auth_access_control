class AddSuspendedToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :suspended, :boolean, default: false
    add_column :users, :suspended_at, :datetime
    add_column :users, :suspended_reason, :text

    add_index :users, :suspended
  end
end
