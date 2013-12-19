class AddAddressToCompanies < ActiveRecord::Migration
  def up
  	add_column :companies, :address, :string
  end

  def down
  	remove_column :companies, :address
  end
end
