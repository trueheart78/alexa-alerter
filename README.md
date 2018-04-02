# Basic Server Response for Alexa Requests

Default setup is a response from the `Faker` gem to respond with a TV-level
hacker statement.

Used the [alexa_rubykit gem][alexa_rubykit] and referenced the
[TaskRabbit "Developing an Amazon Alexa Skill on Rails" post][taskrabbit] by
Brian Leonard.

## Environment Variables

* `OUTBOUND_PHONE_NUMBER`: Number you will be contacting, with leading `+`
* `TWILIO_EMERGENCY_PHONE_NUMBER`: Number you will be calling from when an emergency, with leading `+`
* `TWILIO_NON_EMERGENT_PHONE_NUMBER`: Number you will be messaging from when a non-emergency, with leading `+`
* `TWILIO_ASLEEP_PHONE_NUMBER`: Number you will be calling from when asleep, with leading `+`
* `TWILIO_ACCOUNT_SID`: The account sid for making requests to the Twilio API 
* `TWILIO_AUTH_TOKEN`: The auth token for making requests to the Twilio API 
* `RACK_ENV`: `development` or `production`
* `SKILL_ID`: The `applicationId` of the Amazon Echo skill authorized to access this app.

## Running the Server

It is designed to be run with `Shotgun`, to enable code reloading
without having to restart the server.

```
bundle exec shotgun
```

You can also run it via basic Ruby.

```
bundle exec ruby server.rb
```

## Simple Access via Ngrok

[Ngrok][ngrok] allows access via tunnelling, so that you can interact with the
Sinatra server without having to go through the hassle of deploying it everytime
you make a change.

To access the `Shotgun` server, use:

```
ngrok http 9393
```

If you just want to access the basic Sinatra server, use:

```
ngrok http 4567
```


## Alexa Skill Intent

When working with this application, the following are recommended itents for the
Alexa skill:

```json
{
  "intents": [
    {
      "intent": "Emergency"
    },
    {
      "intent": "NextTenMinutes"
    },
    {
      "intent": "WakeUp"
    },
    {
      "intent": "AMAZON.YesIntent"
    },
    {
      "intent": "AMAZON.NoIntent"
    },
    {
      "intent": "AMAZON.CancelIntent"
    },
    {
      "intent": "AMAZON.StopIntent"
    }
  ]
}
```

[alexa_rubykit]: https://github.com/damianFC/alexa-rubykit
[taskrabbit]: http://tech.taskrabbit.com/blog/2016/12/02/amazon-alexa-rails/
[ngrok]: https://ngrok.com/
