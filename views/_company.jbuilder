json.(company, :id, :name, :email, :city, :country, :phone)
json.href get_company_url(company)
json.owners company.owners.collect{|o| o.id}
