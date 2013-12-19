class CreateOwners < ActiveRecord::Migration
  def up
  	create_table :owners do |t|
		t.string :name
		t.string :passport
		t.integer :company_id
	end
  end

  def down
  	drop_table :owners
  end
end
