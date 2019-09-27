# ContextRequestTrackingSubscriber

[![Gem Version](https://badge.fury.io/rb/context-request-subscriber.svg)](https://badge.fury.io/rb/context-request-subscriber)
[![Build Status](https://api.travis-ci.org/MarcGrimme/context-request-subscriber.svg?branch=master)](https://secure.travis-ci.org/MarcGrimme/context-request-subscriber)
[![Depfu](https://badges.depfu.com/badges/4287422744e2835166219de410c55e52/count.svg)](https://depfu.com/github/MarcGrimme/context-request-middleware?project_id=9487)
[![Coverage](https://marcgrimme.github.io/context-request-subscriber/badges/coverage_badge_total.svg)](https://marcgrimme.github.io/context-request-subscriber/coverage/index.html)
[![RubyCritic](https://marcgrimme.github.io/context-request-subscriber/badges/rubycritic_badge_score.svg)](https://marcgrimme.github.io/context-request-subscriber/tmp/rubycritic/overview.html)

*ContextRequestTrackingSubscriber* is a Ruby written consumer/subscriber to a queue providing context request messages. The default implementation connects to [RabbitMQ](https://www.rabbitmq.com/) but should be exchangable by overwriting it.

## TODOs

Words of warning:

This software is still in a very early state of development.
There have to be a lot of further improvements incorporated. Some are:

* extract the RabbitMQ logic (perhaps create a gem and have the subscriber standalone ...)
* Much better error handling for the JsonApiPushHandler logic
* Json Schema validation
* Integration to Kafka instead of RabbitMQ (do we need a subscriber there at all??) or can we stick with the middleware
* ...

## What is Context Request Tracking

Every request entering a multi service framework leaves a trail of services it hits. Independently for if they are synchronously or asynchronously triggered. In order to follow a request through an application the well known X_REQUEST_ID http header was introduced to push through all requests and therefore track it through the application.

Though the connection from the request to the user or even to the session - let's call it context - is for some use cases of importance. To simplify and provide a normalized way this subscriber is created.

It will just consume these context and request messages.

```
---------------------------
| Request                 |
| request_context: string | 
| ...                     | ------<> -----------------------
---------------------------  n:1     | Context             |
                                     | context_id: string  |
                                     | owner_id: string    |
                                     | ...                 |
                                     -----------------------
```

Request messages are messages describing an event in each application of the stack the request goes through. The schema of the request can he found here.
A context is the second message supported by this subscriber that basically connects multiple requests to one another. The *request_context* maps each request to their respective context.

To uniquely describe a context a *context_id* has to be presented in each context message. Each request message also has to provide a *request_context* which is the same as the *context_id* it relates to (see above). The *app_id* references the application involved (it's not really yet clear if the app_id belongs to the context or the request).

## Handlers

The subscriber receive these messages and then has to decide what to do with them. This logic is bundled into the handlers. Each message type can have a different handler configured via the `ContextRequestSubscriber.handlers` configurable. This handler is a hash consisting of keys that map to the message type (*context* or *request*) and a callable object where the constructor is called with the message parameters as a hash. Optionally the constructur can have multiple options to be passed. These are the configurables the come from `ContextRequestSubscriber.handler_params`. 

## ContextRequestMiddleware

To provide these messages from a Rails application look at [ContextRequestMiddleware](https://github.com/MarcGrimme/context-request-middleware)

## Configuration

The file [config/environment.rb](config/environment.rb) describes the different settings to be configured.

The following environment variables mainly to configure RabbitMQ are supported.

### Handlers

A hash of handlers handling the payload of the messages.

Default: [ContextRequestSubscriber.handler](lib/context_request_subscriber.rb#L41-L49)

## Installation

```
# In your gemfile
gem 'context-request-subscriber'
```

## Usage

To start the subscriber issue

```
./bin/subscriber
```

## Development

After checking out the repo, run `bundle update` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/marcgrimme/context-request-subscriber/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
