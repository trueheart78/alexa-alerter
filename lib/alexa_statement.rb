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
