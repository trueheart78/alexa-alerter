require 'spec_helper'
require 'alexa_statement'

RSpec.describe AlexaStatement do
  subject { described_class.new(fake_twilio_handler).script }

  before do
    allow(fake_twilio_handler).to receive(:delivered?).and_return delivered
    allow(fake_twilio_handler).to receive(:emergent?).and_return emergent
    allow(fake_twilio_handler).to receive(:non_emergent?).and_return non_emergent
    allow(fake_twilio_handler).to receive(:asleep?).and_return asleep
  end

  context 'when emergent' do
    context 'when delivered' do
      it 'it returns the expected string' do
        expect(subject).to eq 'Okay. I have called and texted Josh.'
      end

      let(:delivered) { true }
    end

    context 'when not delivered' do
      it 'it returns the expected string' do
        expect(subject).to eq 'I was unable to get ahold of him. Maybe Siri can help?'
      end

      let(:delivered) { false }
    end

    let(:emergent) { true }
  end

  context 'when non-emergent' do
    context 'when delivered' do
      it 'it returns the expected string' do
        expect(subject).to eq 'Okay. I let him know. Bug him again if he doesn\'t respond in 10 minutes.'
      end

      let(:delivered) { true }
    end

    context 'when not delivered' do
      it 'it returns the expected string' do
        expect(subject).to eq 'I was unable to get ahold of him. Maybe Siri can help?'
      end
    end

    let(:delivered) { false }
    let(:non_emergent) { true }
  end

  context 'when asleep' do
    context 'when delivered' do
      it 'it returns the expected string' do
        expect(subject).to eq 'Calling that sleeping hubby now.'
      end

      let(:delivered) { true }
    end

    context 'when not delivered' do
      it 'it returns the expected string' do
        expect(subject).to eq 'I was unable to get ahold of him. Maybe Siri can help?'
      end

      let(:delivered) { false }
    end
    let(:asleep) { true }
  end

  let(:fake_twilio_handler) { instance_double 'TwilioHandler' }
  let(:delivered)           { true }
  let(:emergent)            { false }
  let(:non_emergent)        { false }
  let(:asleep)              { false }
end
