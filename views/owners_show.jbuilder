json.owners @owners do |json, owner|
	json.partial! '_owner', owner: owner
end
