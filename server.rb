ENV['RACK_ENV'] = 'development' unless ENV['RACK_ENV']

require 'rubygems'
require 'bundler/setup'
Bundler.require :default
require 'json'
require 'logger'
Dotenv.load 'local.env' unless ENV['RACK_ENV'] == 'production'

def send_alert
  require 'twilio-ruby'
  client = Twilio::REST::Client.new(ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN'])

  call = client.api.account.calls.create(
    from: ENV['TWILIO_PHONE_NUMBER'],
    to: ENV['OUTBOUND_PHONE_NUMBER'],
    url: script_url
  )
  Logger.new(STDOUT).info call

  message = client.api.account.messages.create(
    from: ENV['TWILIO_PHONE_NUMBER'],
    to: ENV['OUTBOUND_PHONE_NUMBER'],
    body: 'You are needed.'
  )

  return true if message.error_code == 0
  false
end

def script_url
  uri = URI.parse request.url
  "#{uri.scheme}://#{uri.host}/script"
end

get '/' do
  Faker::Hacker.say_something_smart
end

post '/script' do
  response = Twilio::TwiML::VoiceResponse.new do |r|
    r.say 'You are needed.', voice: 'alice'
    r.dial number: ENV['TWILIO_PHONE_NUMBER']
  end

  content_type 'text/xml'
  return response.to_s
end

post '/help-me' do
  alexa_input = JSON.parse request.body.read
  alexa_response = AlexaRubykit::Response.new
  if AlexaRubykit.valid_alexa? alexa_input
    alexa_request = AlexaRubykit.build_request alexa_input
    if send_alert
      alexa_response.add_speech 'Okay. I have called and texted Josh.'
    else
      alexa_response.add_speech 'I was unable to get ahold of him. Maybe Siri can help.'
    end
  else
    alexa_response.add_speech 'I did not understand you'
  end
  return alexa_response.build_response
end
