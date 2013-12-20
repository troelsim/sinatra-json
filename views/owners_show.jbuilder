json.owners @owners do |owner|
	json.partial! '_owner', owner: owner
end
