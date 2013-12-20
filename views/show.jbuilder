json.company do 
	json.partial! '_company', company: @company
end
if @company.owners.any?
	json.owners @company.owners do |owner|
		json.partial! '_owner', owner: owner
	end
end
