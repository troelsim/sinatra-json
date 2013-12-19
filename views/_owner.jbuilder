json.(owner, :id, :name, :company_id)
json.passport get_passport_url(owner) if owner.has_passport?
