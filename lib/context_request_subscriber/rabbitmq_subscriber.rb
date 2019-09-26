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
    DEFAULT_QUEUE_OPTS = {
      exclusive: false, durable: true
    }.freeze

    DEFAULT_SESSION_PARAMS = {
      threaded: true, automatically_recover: true
    }.freeze

    # @processor the processor to be used to handle the data.
    # @config the configurables supported as follows
    #    session_params: set of session params
    #    url: url to connect to the RabbitMQ Server
    #    heartbeat: heartbeat for the connection. Defaults to nil.
    #    exchange_name: the exchange connected to the queue
    #    exchange_options: the options used to create the exchange if not
    #      existing.
    #    exchange_type: type of the exchange, defaults to topic.
    #    queue_name: the queue where the data is received from.
    #    queue_durable: if the queue is durable. Default: true
    #    queue_auto_delete: if the queue gets autodeleted.
    #    queue_exclusive: default false.
    #    routing_key: the routing_key used. Default nil.
    #    on_error: callable object that handles errors during processing the
    #       message.
    def initialize(**config)
      @error_handler = config[:on_error].new(config[:logger])
      @logger = config[:logger]
      @executor = Processor::Executor.new(config[:logger],
                                          config.slice(:handler_params))
      config_connection(config)

      config_exchange(config)
      config_queue(config)
    end

    def run
      exchange, queue = setup_queue
      @consumer = queue.subscribe(manual_ack: true,
                                  block: false) do |info, properties, payload|
        consume(info, properties, payload)
      end
      join(exchange)
    end

    def join(exchange)
      @join_workpool && exchange.channel.work_pool.join
    end

    private

    def config_connection(config)
      @session_params = config.fetch(:session_params, {})
                              .merge(DEFAULT_SESSION_PARAMS)
      @url = config[:url]
    end

    def config_queue(config)
      @queue_name = config[:queue_name]
      @queue_bindings = config.slice(:routing_key)
      @queue_opts = queue_opts(config)
    end

    def config_exchange(config)
      @exchange_type = config.fetch(:exchange_type, 'topic')
      @exchange_name = config.fetch(:exchange_name,
                                    ContextRequestSubscriber.exchange_name)
      @exchange_opts = config.fetch(:exchange_options, {})
      @join_workpool = config.fetch(:subscriber_join, true)
    end

    # setup the whole message queue settings and return the queue object.
    # Can be overwriten by ContextRequestMiddleware.fetch_exchange_callback
    def setup_queue
      callback = ContextRequestSubscriber.fetch_queue_callback
      if callback
        exchange, queue = callback.call(self)
      else
        channel = create_channel(@session_params)
        exchange = fetch_exchange(channel, @exchange_type, @exchange_name,
                                  @exchange_opts)
        queue = bind_queue(channel, exchange)
      end
      [exchange, queue]
    end

    # Default behaviour is that all messages are consumed by just
    # passing the information to the processor. If any part fails
    # the application needs to gracefully handle because the message
    # is acked automatically.
    # To change that behaviour overwrite the fetch_queue_callback
    # and extend the Processor to handle the ack method.
    def consume(info, properties, payload)
      @executor.run(info, properties, payload)
      @executor.ack(@channel)
    rescue StandardError => e
      handle_error(e, info, properties, payload)
    end

    def create_channel(options = {})
      connection = Bunny.new(@url, options)
      connection.start

      connection.create_channel
    end

    # return the exchange Bunny object and do the whole setup around it.
    def fetch_exchange(channel, exchange_type, exchange_name, exchange_opts)
      channel.exchanges[exchange_name] ||
        bunny_exchange(channel, exchange_type, exchange_name, exchange_opts)
    end

    def bind_queue(channel, exchange)
      queue = channel.queue(@queue_name, @queue_opts)
      queue.bind(exchange, @queue_bindings)
      queue
    end

    def handle_error(error, info, properties, payload)
      @error_handler&.call(error, info, properties, payload)
    end

    def bunny_exchange(channel, type, name, opts)
      Bunny::Exchange.new(channel, type, name, opts)
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
