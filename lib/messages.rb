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
