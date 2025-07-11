class MakeOrganizationIdNullableInActivityLogs < ActiveRecord::Migration[8.0]
  def change
    change_column_null :activity_logs, :organization_id, true
  end
end
