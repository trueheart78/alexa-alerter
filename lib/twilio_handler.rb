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
