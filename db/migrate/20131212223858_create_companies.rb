class CreateCompanies < ActiveRecord::Migration
  def up
  	create_table :companies do |t|
		t.string :name
		t.string :city
		t.string :country
		t.string :email
		t.string :phone
	end
  end

  def down
  	drop_table :companies
  end
end
