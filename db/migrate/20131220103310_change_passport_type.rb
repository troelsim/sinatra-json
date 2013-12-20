class ChangePassportType < ActiveRecord::Migration
  def up
  	change_column :owners, :passport, :text
  end

  def down
  	change_column :owners, :passport, :string
  end
end
