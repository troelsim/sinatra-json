json.companies @companies do |json, company|
	json.partial! '_company', company: company
end
