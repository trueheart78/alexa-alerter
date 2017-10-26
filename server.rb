require 'rubygems'
require 'bundler/setup'
Bundler.require :default
require 'json'
require 'logger'

get '/' do
  Faker::Hacker.say_something_smart
end

post '/' do
  alexa_input = JSON.parse request.body.read
  alexa_response = AlexaRubykit::Response.new
  if AlexaRubykit.valid_alexa? alexa_input
    alexa_request = AlexaRubykit.build_request alexa_input
    Logger.new(STDOUT).info alexa_request
    alexa_response.add_speech "#{alexa_request.name} (#{alexa_request.type})"
  else
    alexa_response.add_speech 'I did not understand you'
  end
  return alexa_response.build_response
end
