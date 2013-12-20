json.companies @companies do |company|
	json.partial! '_company', company: company
end
