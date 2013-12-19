json.company do |json|
	json.partial! '_company', company: @company
end
if @company.owners.any?
json.owners @company.owners do |json, owner|
	json.(owner, :id, :name, :passport, :company_id)
end
end
