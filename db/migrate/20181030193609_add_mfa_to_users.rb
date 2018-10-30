class AddMfaToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :mfa_access_token, :string
    add_column :users, :mfa_authenticated, :boolean
  end
end
