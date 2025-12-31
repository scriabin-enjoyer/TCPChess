# frozen_string_literal: true

require_relative 'input_parser'


# Represents all Clients connected to the chat lobby. I use a crude textual
# format to multiplex input onto stdin:
# "1 blah blah blah 2 yadda yadda yadda ... <NUMBER> <TEXT>"
# The above represents an asynchronous stream of messages sent from an
# arbitrary number of clients. Each client is identified with a number. This
# code runs in the main thread.
class Client
  include InputParser

  def initialize(stream_splitter)
    @stream_splitter = stream_splitter
    @input = nil
    @payload = nil
  end

  def start
    loop do
      read
      parse
      delegate
    end
  end

  def byebye
    puts 'Client: Bye Bye'
  end

  private

  def read
    @input = gets.chomp.downcase
  end

  def parse
    @payload = parse_input(@input)
  end

  def delegate
    case @payload[:method]
    when :quit
      puts 'Client: shutting down'
      signal_shutdown
    when :error
      puts 'error: bad input'
    when :messages
      notify_stream_splitter
    else
      raise StandardError, "I don't know wtf happened, sorry bro"
    end
  end

  def signal_shutdown
    @stream_splitter.signal_shutdown
  end

  def notify_stream_splitter
    @stream_splitter.receive_notification(@payload)
  end
end
