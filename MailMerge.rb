# frozen_string_literal: true

# Import your dependencies
require 'sinatra'
require 'csv'
require 'dotenv/load'
require 'nylas'
require 'sinatra/flash'

# Use sessions
enable :sessions

# Initialize your Nylas API client
nylas = Nylas::Client.new(
  api_key: ENV['V3_TOKEN']
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
  erb :main, layout: :layout
end

# When we submit the information
post '/' do
  # Set session variables
  session[:subject] = params[:subject]
  session[:body] = params[:body]
  if params[:subject] == '' || params[:body] == '' || params[:mergefile] == ''
    flash[:error] = 'You must specify all fields'
    redirect to('/')
  else
    # Clear session variables
    session[:subject] = ''
    session[:body] = ''
    # Get parameters from form
    subject = params[:subject]
    body = params[:body]
    params[:mergefile]
    # Auxiliar variables
    email = ''
    emails = []
    # Load CSV file
    mergemail_file = CSV.parse(File.read(params[:mergefile]), headers: true)
    # Get CSV headers (Column titles)
    headers = mergemail_file.headers
    # Go through each line of the CSV file
    mergemail_file.each do |line|
      # Assign parameters to auxiliar variables
      subject_replaced = subject
      body_replaced = body
      # Loop through all headers
      headers.each do |header|
        # If any header matches the subject, then replace it
        subject_replaced = subject_replaced.gsub(/{#{header}}/, line[header.to_s]) if subject.match(/{#{header}}/)
        # If any header matches the body, then replace it
        body_replaced = body_replaced.gsub(/{#{header}}/, line[header.to_s].to_s) if body.match(/{#{header}}/)
      end
      # Get Name and Last_Name if both exist
      begin
        full_name = line['Name'] + line['Last_Name']
      rescue StandardError
        # Get Name only
        full_name = line['Name']
      end
      # Get email and send it to an array
      email = line['Email']
      emails.push(email)
      # Do we have any attachments?
      file = ''
      unless line['Attachment'].nil?
        file = Nylas::FileUtils.attach_file_request_builder("attachments/#{line['Attachment']}")
      end
      # Try to send an email to each email on the CSV file
      begin
        request_body = if file.empty?
                         # Call the Send endpoint and send an email for each occurrence on the CSV
                         {
                           subject: subject_replaced,
                           body: body_replaced,
                           to: [{ name: full_name, email: line['Email'] }]
                         }
                       else
                         # Call the Send endpoint and send an email for each occurrence on the CSV
                         # and add the attachment
                         {
                           subject: subject_replaced,
                           body: body_replaced,
                           to: [{ name: full_name, email: line['Email'] }],
                           attachments: [file]
                         }
                       end
        email, = nylas.messages.send(identifier: ENV['GRANT_ID'], request_body: request_body)
      rescue StandardError => e
        # Something went wrong
        puts e.message
      end
    end
    # Call the page to display sent emails
    redirect to("/result?emails=#{emails}")
  end
end
