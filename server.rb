ENV['RACK_ENV'] = 'development' unless ENV['RACK_ENV']

require 'rubygems'
require 'bundler/setup'
Bundler.require :default
require 'active_support/inflector'
require 'json'
require 'logger'
Dotenv.load 'local.env' unless ENV['RACK_ENV'] == 'production'

def development?
  ENV['RACK_ENV'] == 'development'
end

def production?
  ENV['RACK_ENV'] == 'production'
end

def authorized?(json)
  return ENV['SKILL_ID'] == json['session']['application']['applicationId']
end

class Messages
  class << self
    def emergent_message
      [
        'You are needed',
        'You are SO needed',
        'Plz. It\'s urgent',
        'HALP',
        'Drop everything now'
      ].sample
    end

    def non_emergent_message
      [
        'When you get a minute, I could use some help',
        'It\'s not urgent, but I could use your help',
        'Hey. You. Take a break soon, I need something',
        'Got a minute to help me? It\'s not urgent'
      ]
    end

    def wake_up_message
      [
        'Wake up, you may be snoring',
        'Hey, sunshine. Wake up',
        'I love you, but you need to wake up'
      ].sample
    end
  end
end

class AlexaStatement
  def initialize(twilio_handler)
    @twilio_handler = twilio_handler
  end

  def script
    return responses[:error] unless twilio_handler.delivered?
    return responses[:emergent] if twilio_handler.emergent?
    return responses[:woken] if twilio_handler.asleep?
    responses[:non_emergent]
  end

  def self.did_not_understand_script
    'I did not understand you'
  end

  def self.youre_not_my_real_parent
    "You can't make me! You're not my real #{[:mom, :dad].sample}!"
  end

  private

  attr_reader :twilio_handler

  def responses
    {
      emergent: 'Okay. I have called and texted Josh.',
      non_emergent: 'Okay. I let him know. Bug him again if he doesn\'t respond in 10 minutes',
      woken: 'Calling that sleeping hubby now',
      error: 'I was unable to get ahold of him. Maybe Siri can help?',
    }
  end
end

class TwilioHandler
  def initialize(intent, request_url)
    @intent = intent.underscore.to_sym
    @request_url = request_url
    @status = { call: false, message: false }
  end

  def delivered?
    return status[:call] && status[:message] if emergent?
    return status[:message] if non_emergent?
    return status[:call] if asleep?
    false
  end

  def valid?
    %i(emergency next_ten_minutes stop_snoring).include? intent
  end

  def emergent?
    intent == :emergency
  end

  def non_emergent?
    intent == :next_ten_minutes
  end

  def asleep?
    intent == :stop_snoring
  end

  def make_contact
    return false unless valid?
    send_message if message?
    make_phone_call if call?
    delivered?
  end

  private

  attr_reader :intent, :status, :request_url

  def message?
    emergent? || non_emergent?
  end

  def call?
    emergent? || asleep?
  end

  def make_phone_call
    call = twilio_client.api.account.calls.create(
      from: phone_number,
      to: outbound_phone_number,
      url: script_url
    )

    status[:call] = true
  end

  def send_message
    message = twilio_client.api.account.messages.create(
      from: phone_number,
      to: outbound_phone_number,
      body: message_text
    )

    status[:message] = true if message.error_code.zero?
  end

  def message_text
    return Messages.emergent_message if emergent?
    Messages.non_emergent_message
  end

  def script_url
    return emergent_url if emergent?
    return wake_up_url if asleep?
    nil
  end

  def emergent_url
    url '/script'
  end

  def wake_up_url
    url '/wake-up'
  end

  def url(path)
    URI.parse(request_url).tap do |uri|
      uri.path = path
    end.to_s
  end

  def phone_number
    return ENV['TWILIO_EMERGENCY_PHONE_NUMBER'] if emergent?
    return ENV['TWILIO_ASLEEP_PHONE_NUMBER'] if asleep?
    ENV['TWILIO_NON_EMERGENT_PHONE_NUMBER']
  end

  def outbound_phone_number
    ENV['OUTBOUND_PHONE_NUMBER']
  end

  def twilio_client
    @twilio_client ||= Twilio::REST::Client.new(ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN'])
  end
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

if development?
  get '/wake_up' do
    content_type 'text/json'
    return File.read('specs/fixtures/requests/wake_up.json')
  end

  get '/valid' do
    json = JSON.parse File.read('specs/fixtures/requests/wake_up.json')
    content_type 'text/json'
    return { authorized_skill: authorized?(json) }.to_json
  end
end

get '*' do
  content_type 'text/plain'
  return Faker::Hacker.say_something_smart
end
