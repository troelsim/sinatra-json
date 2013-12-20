require 'json'
require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/jbuilder'
require 'protected_attributes'
require 'base64'
require 'rubygems'

configure :development do
	set :database, "sqlite3:///data.db"
end

configure :production do
	puts "DATABASE_URL: #{ENV['HEROKU_POSTGRESQL_GRAY_URL']}"
	db = URI.parse(ENV['HEROKU_POSTGRESQL_GRAY_URL'])
	ActiveRecord::Base.establish_connection(
		:adapter => 'postgresql',
		:host => db.host,
		:username => db.user,
		:password => db.password,
		:database => db.path[1..-1],
		:encoding => 'utf8'
	)
#	ActiveRecord::Base.logger.level=1
end

configure do
	set :markdown, :layout_engine => :erb
	set :server_dir, Dir.pwd
	@server_dir =  Dir.pwd
end

# Models


class Company < ActiveRecord::Base
	has_many :owners
	attr_protected :id
	validates :name, :address, :city, :country, presence: true
end

class Owner < ActiveRecord::Base
	belongs_to :company
	attr_protected :id
	validates :name, presence: true
	
	def has_passport?
		return self.passport != nil
	end
end

not_found do
	halt 404
end

get "/" do
	send_file "public/index.html"
end

get "/api_doc" do
	markdown :api_doc
end

get "/readme" do
	markdown :readme
end

get "/companies/?" do
	@companies = Company.all
	jbuilder :index
end

get "/companies/:id"  do
	@company = Company.find(params[:id])
	jbuilder :show
end

post "/companies" do
	jparams = JSON.parse(request.body.read.to_s)
	@company = Company.new(jparams['company'])
	@company.save!
	jbuilder :show
end

delete "/companies/:id" do
	@company = Company.find(params[:id])
	@company.delete
	""
end

put "/companies/:id" do
	jparams = JSON.parse(request.body.read.to_s)
	puts jparams[:company]
	@company = Company.find(params[:id])
	@company.update_attributes!(jparams["company"])
	jbuilder :show
end

get "/owners?" do
	@owners = Owner.all
	jbuilder :owners_show
end

get "/owners/:id" do
	@owner = Owner.find(params[:id])
	jbuilder :owner_show
	return_error(404,ex)
end

post "/owners" do
	jparams = JSON.parse(request.body.read.to_s)
	company_id = jparams['owner']['company_id']
	@company = Company.find(company_id)
	@owner=@company.owners.new(name: jparams['owner']['name'])
	passport = get_passport(jparams)
	@owner.update_attributes(passport: passport)
	@company.save!
	status 201
	jbuilder :owner_show
end

put "/owners/:id" do
	jparams = JSON.parse(request.body.read.to_s)
	@owner = Owner.find(params[:id])
	passport = get_passport(jparams)
	@owner.update_attributes(name: jparams["owner"]["name"], passport: passport)
	jbuilder :owner_show
end

get "/owners/:id/passport.pdf" do
	@owner = Owner.find(params[:id])
	content_type 'application/pdf'
	response.write(Base64.urlsafe_decode64(@owner.passport))
end

delete "/owners/:id" do
	@owner = Owner.find(params[:id])
	@owner.delete
	""
end

helpers do
	def get_company_url(company)
		"#{get_base_url}/companies/#{company.id}"
	end

	def get_base_url
		"#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
	end

	def get_passport_url(owner)
		"#{get_base_url}/owners/#{owner.id}/passport.pdf"
	end

	def get_passport(jparams) # Saves the file in jparams if there is one, returns 400 if it's invalid
		start = jparams["owner"]["passport_file"].index("base64,")+7
		intro = jparams["owner"]["passport_file"][0 .. start]
		if intro.match("application/pdf") or intro.match("application/x-pdf")
			return jparams["owner"]["passport_file"][start .. -1]
		else
			raise ArgumentError, "Passport Not PDF"
		end
	end
	
end
