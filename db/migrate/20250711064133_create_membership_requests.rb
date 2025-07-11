class CreateMembershipRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :membership_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.string :status, default: "pending"
      t.text :message

      t.timestamps
    end

    add_index :membership_requests, [ :user_id, :organization_id ], unique: true
  end
end
