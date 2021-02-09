require 'spec_helper'
require 'twilio_handler'

RSpec.describe TwilioHandler do
  subject { TwilioHandler.new intent, request_url }

  it 'is the expected version' do
    expect(subject).to be_a TwilioHandler
  end

  let(:intent)      { 'Emergency' }
  let(:request_url) { 'http://sample.url.com/path' }
end
