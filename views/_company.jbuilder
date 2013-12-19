json.(company, :id, :name, :address, :city, :country, :phone, :email)
json.href get_company_url(company)
json.owners company.owners.collect{|o| o.id}
