require 'json'
require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/jbuilder'
require 'protected_attributes'

configure :development do
	set :database, "sqlite3:///data.db"
end

configure :production do
	puts "DATABASE_URL: #{ENV['HEROKU_POSTGRESQL_GRAY_URL']}"
	db = URI.parse(ENV['DATABASE_URL'])
	ActiveRecord::Base.establish_connection(
		:adapter => 'postgresql',
		:host => db.host,
		:username => db.user,
		:passowrd => db.password,
		:database => db.path[1..-1],
		:encoding => 'utf8'
	)
end


class Company < ActiveRecord::Base
	has_many :owners
	attr_protected :id
end

class Owner < ActiveRecord::Base
	belongs_to :company
	attr_protected :id
end

get "/" do
	redirect "/index2.html"
end

get "/companies/?", :provides => :json do
	@companies = Company.all
	jbuilder :index
end

get "/companies/:id", :provides => :json  do
	begin
		@company = Company.find(params[:id])
		jbuilder :show
	rescue ActiveRecord::RecordNotFound
		halt(404)
 	end
end

post "/companies" do
	jparams = JSON.parse(request.body.read.to_s)
	@company = Company.new(jparams['company'])
	#@company = Company.new(params.require(:company))
	if @company.save
		jbuilder :show
	else
		halt 500
	end
end

delete "/companies/:id" do
	begin
		@company = Company.find(params[:id])
		@company.delete
		redirect "/companies"
	rescue ActiveRecord::RecordNotFound
		halt(404)
	end
end

put "/companies/:id" do
	puts "lol"
	jparams = JSON.parse(request.body.read.to_s)
	begin
		puts jparams[:company]
		@company = Company.find(params[:id])
		@company.update_attributes(jparams["company"])
		jbuilder :show
	rescue ActiveRecord::RecordNotFound => e
		puts e.message
		puts e.backtrace
		halt(404)
	end
end

get "/owners" do
	@owners = Owner.all
	jbuilder :owners_show
end

get "/owners/:id" do
	@owner = Owner.find(params[:id])
	jbuilder :owner_show
end

post "/owners" do
	jparams = JSON.parse(request.body.read.to_s)
	company_id = jparams['owner']['company_id']
	puts company_id
	@company = Company.find(company_id)
	# Is there a file attached?
	@owner=@company.owners.new(jparams['owner'])
	#@company = Company.new(params.require(:company))
	if @company.save
		status 201
		jbuilder :owner_show
	else
		halt 500
	end
end

put "/owners/:id" do
	jparams = JSON.parse(request.body.read.to_s)
	begin
		puts jparams[:owner]
		@owner = Owner.find(params[:id])
		@owner.update_attributes(jparams["owner"].slice("name", "passport"))
		jbuilder :owner_show
	rescue ActiveRecord::RecordNotFound => e
		puts e.message
		puts e.backtrace
		halt(404)
	end
end

get "/fucknudig" do
	"Hvad"
end

put "/owners/:id/passport.pdf" do
	folder = "#{Dir.pwd}/passports"
	owner_id = params[:id]
	timestamp = Time.now.strftime("%Y-%m-%d-%H-%M-%S.%L")
	filename = "#{folder}/owner-#{owner_id}-#{timestamp}.pdf"
	puts filename
	File.open(filename, 'w') do |f|
		f.write(params[:passport_file][:tempfile].read)
	end
	"Done"
end

delete "/owners/:id" do
	begin
		@owner = Owner.find(params[:id])
		@owner.delete
		status 200
		""
	rescue ActiveRecord::RecordNotFound
		halt(404)
	end
end

helpers do
	def get_company_url(company)
		"#{get_base_url}/companies/#{company.id}"
	end

	def get_base_url
		"http://127.0.0.1:9393"
	end
end
