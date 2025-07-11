class CreateParticipationRules < ActiveRecord::Migration[8.0]
  def change
    create_table :participation_rules do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :rule_type, null: false
      t.jsonb :conditions, default: {}
      t.jsonb :actions, default: {}
      t.boolean :active, default: true
      t.integer :priority, default: 0
      t.text :description

      t.timestamps
    end

    add_index :participation_rules, [ :organization_id, :rule_type ]
    add_index :participation_rules, [ :organization_id, :active ]
  end
end
