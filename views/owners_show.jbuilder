json.owners @owners do |json, owner|
	json.(owner, :id, :name, :company_id)
end
