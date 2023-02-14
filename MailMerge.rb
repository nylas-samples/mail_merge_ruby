# Import your dependencies
require 'sinatra'
require 'csv'
require 'dotenv/load'
require 'nylas'
require 'sinatra/flash'

# Use sessions
enable :sessions

# Initialize your Nylas API client
nylas = Nylas::API.new(
    app_id: ENV["CLIENT_ID"],
    app_secret: ENV["CLIENT_SECRET"],
    access_token: ENV["ACCESS_TOKEN"]
)

# Display emails that were sent
get '/result' do
	# Get the emails array
	@emails = params[:emails]
	erb :show_emails
end

# Main page with form
get '/' do
	# Read session variables
	@subject = session[:subject]
	@body = session[:body]
	erb :main, :layout => :layout
end

# When we submit the information
post '/' do
	# Set session variables
	session[:subject] = params[:subject]
	session[:body] = params[:body]
	if(params[:subject] == '' || params[:body] == '' || params[:mergefile] == '')
		flash[:error] = "You must specify all fields"
		redirect to("/")
	else
		# Clear session variables
		session[:subject] = ''
		session[:body] = ''
		# Get parameters from form
		subject = params[:subject]
		body = params[:body]
		mergefile = params[:mergefile]
		# Auxiliar variables
		email = ''
		emails = Array.new
		# Load CSV file
		mergemail_file = CSV.parse(File.read(params[:mergefile]), headers: true)
		# Get CSV headers (Column titles)
		headers = mergemail_file.headers()
		# Go through each line of the CSV file
		mergemail_file.each{ |line|
			# Assign parameters to auxiliar variables
			subject_replaced = subject
			body_replaced = body
			# Loop through all headers
			headers.each { |header|
				# If any header matches the subject, then replace it
				if(subject.match(/{#{header}}/))
					subject_replaced = subject_replaced.gsub(/{#{header}}/, line["#{header}"])
				end
				# If any header matches the body, then replace it
				if(body.match(/{#{header}}/))
					body_replaced = body_replaced.gsub(/{#{header}}/, line["#{header}"])
				end
			}
			# Get Name and Last_Name if both exist
			begin
				full_name = line["Name"] + line["Last_Name"]
			rescue => error
			# Get Name only
				full_name = line["Name"]
			end
			# Get email and send it to an array
			email = line["Email"]
			emails.push(email)
			# Try to send an email to each email on the CSV file
			begin
				# Call the Send endpoint and send an email for each occurrence on the CSV file
				message = nylas.send!(to: [{ email: line["Email"], name: full_name }],
							     subject: subject_replaced, body: body_replaced)
			rescue => error
				# Something went wrong
				puts error.message
			end
		}
	# Call the page to display sent emails
	redirect to("/result?emails=#{emails}")
	end
end
