class CreateParentalConsents < ActiveRecord::Migration[8.0]
  def change
    create_table :parental_consents do |t|
      t.references :user, null: false, foreign_key: true
      t.string :parent_email, null: false
      t.string :consent_token, null: false
      t.datetime :consent_requested_at, null: false
      t.datetime :consented_at
      t.datetime :expires_at, null: false
      t.boolean :consented, default: false
      t.text :notes

      t.timestamps
    end

    add_index :parental_consents, :consent_token, unique: true
    add_index :parental_consents, :parent_email
  end
end
