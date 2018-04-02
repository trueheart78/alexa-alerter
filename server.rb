ENV['RACK_ENV'] = 'development' unless ENV['RACK_ENV']

require 'rubygems'
require 'bundler/setup'
Bundler.require :default
Bundler.require :development if ENV['RACK_ENV'] == 'development'
require 'active_support/inflector'
require 'json'
require 'logger'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))

Dotenv.load 'local.env' if ENV['RACK_ENV'] == 'development'
Dotenv.load 'test.env' if ENV['RACK_ENV'] == 'test'

require 'messages'
require 'twilio_handler'
require 'alexa_statement'

def development?
  ENV['RACK_ENV'] == 'development'
end

def production?
  ENV['RACK_ENV'] == 'production'
end

def authorized?(json)
  return ENV['SKILL_ID'] == json['session']['application']['applicationId']
end

post '/script' do
  response = Twilio::TwiML::VoiceResponse.new do |r|
    r.say Messages.emergent_message, voice: 'alice'
    r.dial number: ENV['TWILIO_PHONE_NUMBER']
  end

  content_type 'text/xml'
  return response.to_s
end

post '/wake-up' do
  response = Twilio::TwiML::VoiceResponse.new do |r|
    r.say Messages.wake_up_message, voice: 'alice'
    r.dial number: ENV['TWILIO_PHONE_NUMBER']
  end

  content_type 'text/xml'
  return response.to_s
end

post '/help-me' do
  alexa_json = JSON.parse request.body.read
  alexa_response = AlexaRubykit::Response.new
  if AlexaRubykit.valid_alexa? alexa_json
    alexa_request = AlexaRubykit.build_request alexa_json
    if authorized? alexa_json
      if alexa_request.is_a? AlexaRubykit::IntentRequest
        twilio = TwilioHandler.new(alexa_request.name, request.url)
        twilio.make_contact
        alexa_response.add_speech AlexaStatement.new(twilio).script
      end
    else
      alexa_response.add_speech AlexaStatement.youre_not_my_real_parent
    end
  else
    alexa_response.add_speech AlexaStatement.did_not_understand_script
  end
  return alexa_response.build_response
end

get '*' do
  content_type 'text/plain'
  return Faker::Hacker.say_something_smart
end
