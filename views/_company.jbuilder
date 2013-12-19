json.(company, :id, :name, :email, :city, :country, :phone)
json.href get_company_url(company)
json.owners company.owners.collect{|o| o.id}
#company.owners.each do |owner|
#	puts owner.name
#	json.owners owner.id
#end

#json.owners company.owners do |json, owner|
#	json.(owner, :id)
#end
