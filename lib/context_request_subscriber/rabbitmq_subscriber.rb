# frozen_string_literal: true

require 'bunny'

module ContextRequestSubscriber
  # The subscriber to attach to the exchange to process the
  # ContextRequest data.
  #
  # ErrorHandler is a Callable object that gets called for any exception
  # during the execution of the processor.
  # The call method gets passed the following information:
  #   @exception the exception caught
  #   @delivery_info the delivery_info object
  #   @properties properties passed in the message (headers, ..)
  #   @payload the payload of the message
  # The ErrorHandler has to decide what to do with the message. If none
  # is given the error will be ignored!
  class RabbitMQSubscriber
    class ExchangeNotFound < StandardError; end

    DEFAULT_QUEUE_OPTS = {
      exclusive: false,
      durable: true
    }.freeze

    # @processor the processor to be used to handle the data.
    # @config the configurables supported as follows
    #    session_params: set of session params
    #    url: url to connect to the RabbitMQ Server
    #    heartbeat: heartbeat for the connection. Defaults to nil.
    #    exchange_name: the exchange connected to the queue
    #    queue_name: the queue where the data is received from.
    #    queue_durable: if the queue is durable. Default: true
    #    queue_auto_delete: if the queue gets autodeleted.
    #    queue_exclusive: default false.
    #    routing_key: the routing_key used. Default nil.
    #    on_error: callable object that handles errors during processing the
    #       message.
    def initialize(processor, **config)
      @exchange_name = config[:exchange_name]
      @queue_name = config[:queue_name]
      @queue_bindings = config[:routing_key]
      @processor = processor
      @queue_opts = queue_opts(config)
      @session_params = config.fetch(:session_params, {})
      @url = config[:url]
    end

    def run
      channel = create_channel
      queue = bind_queue
      @consumer = queue.subscribe(manual_ack: true,
                                  block: false) do |info, properties, payload|
        run_ack(channel, info, properties, payload)
      end
    end

    private

    def run_ack(channel, info, properties, payload)
      Processor.run(info, properties, payload)
      channel.ack(info.delivery_tag)
    rescue StandardError => e
      handle_error(e, info, properties, payload)
    end

    def create_channel(options = {})
      @bunny = Bunny.new(@url, options)
      @bunny.start

      @channel = @bunny.create_channel
      @channel.confirm_select
      @exchange = @channel.exchanges.fetch(@exchange_name) do
        raise ExchangeNotFound, @exchange_name
      end
      @exchange.channel
    end

    def bind_queue
      queue = @channel.queue(@queue_name, @queue_opts)
      queue.bind(@exchange, @queue_bindings)
      queue
    end

    def handle_error(error, info, properties, payload)
      @error_handler.call(error, info, properties, payload) if error_handler
    end

    def queue_opts(config)
      opts = config.slice(:queue_durable, :queue_auto_delete, :queue_exclusive)
      opts.dup.each do |k, _v|
        opts[k.to_s.sub(/^queue_/, '').to_sym] = opts.delete(k)
      end
      DEFAULT_QUEUE_OPTS.merge(opts)
    end
  end
end
