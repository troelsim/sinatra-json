require "./app"

class App < Sinatra::Application
	configure do
		set :dump_errors, false

		set :raise_errors, true

		set :show_exceptions, false
	end
end

class ExceptionHandling
	def initialize(app)
		@app = app
	end
 
	def call(env)
		begin
			begin
				@app.call env
			rescue ActiveRecord::RecordNotFound
			# Set the status code corresponding to the type of exception
				puts "Fik 404"
				status=404
				raise 
			rescue ActiveRecord::RecordInvalid,JSON::JSONError
				status=400
				raise
			end
		rescue => ex
			puts "Status: #{status}"
			status ||= 500
			## Uncaught errors!
			# Send error and stack trace to log
			env['rack.errors'].puts ex
			env['rack.errors'].puts ex.backtrace.join("\n")
			env['rack.errors'].flush
			hash = { :error => { :message => ex.to_s }}
			hash[:error][:backtrace] = ex.backtrace if ENV['RACK_ENV']=='development'
			# Return the error description as JSON
			return "#{status}",{'Content-Type' => 'application/json'}, [MultiJson.dump(hash)]
		end
	end

end


use ExceptionHandling
run App
