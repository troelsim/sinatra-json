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
end

configure do
	set :markdown, :layout_engine => :erb
	set :server_dir, Dir.pwd
	@server_dir =  Dir.pwd
end

class Company < ActiveRecord::Base
	has_many :owners
	attr_protected :id
end

class Owner < ActiveRecord::Base
	belongs_to :company
	attr_protected :id
	
	def has_passport?
		return File.file?("#{Dir.pwd}#{self.passport}")
	end

	def passport_path
		return self.has_passport? ? "#{Dir.pwd}#{self.passport}" : nil
	end
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
	puts @owner.has_passport?
	jbuilder :owner_show
end

post "/owners" do
	jparams = JSON.parse(request.body.read.to_s)
	company_id = jparams['owner']['company_id']
	puts company_id
	@company = Company.find(company_id)
	@owner=@company.owners.new(name: jparams['owner']['name'])
	passport = save_passport(@owner,jparams)
	@owner.update_attributes(passport: passport)
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
		# Is there a file?
		
		@owner = Owner.find(params[:id])
		passport = save_passport(@owner,jparams)
		@owner.update_attributes(name: jparams["owner"]["name"], passport: passport)
		jbuilder :owner_show
	rescue ActiveRecord::RecordNotFound => e
		puts e.message
		puts e.backtrace
		halt(404)
	end
end

get "/owners/:id/passport.pdf" do
	@owner = Owner.find(params[:id])
	send_file @owner.passport_path
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
		"#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
	end

	def get_passport_url(owner)
		"#{get_base_url}/owners/#{owner.id}/passport.pdf"
	end

	def save_passport(owner, jparams) # Saves the file in jparams if there is one, returns 400 if it's invalid
		if jparams["owner"]["passport_file"]
			owner_id = params[:id]
			folder = "/passports"
			timestamp = Time.now.strftime("%Y-%m-%d-%H-%M-%S.%L")
			filename = "#{folder}/owner-#{owner_id}-#{timestamp}.pdf"
			print "Writing to #{filename}..."
			begin
				File.open("#{settings.server_dir}#{filename}", 'w') do |f|
					# Strip the data type by finding where the "real data" starts
					start = jparams["owner"]["passport_file"].index("base64,")+7
					f.write(Base64.urlsafe_decode64(jparams["owner"]["passport_file"][start .. -1]))
				end
			rescue ArgumentError # If the data is not valid Base64
				puts "error."
				halt 400
			end
			puts "done."
			# Return *relative* file path
			return filename
		else
			return nil
		end
	end
end
