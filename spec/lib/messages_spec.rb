require 'spec_helper'
require 'messages'

RSpec.describe Messages do
  describe '.emergent_message' do
    subject { described_class.emergent_message }

    it { is_expected.to be_a String }
  end

  describe '.non_emergent_message' do
    subject { described_class.non_emergent_message }

    it { is_expected.to be_a String }
  end

  describe '.wake_up_message' do
    subject { described_class.wake_up_message }

    it { is_expected.to be_a String }
  end
end
