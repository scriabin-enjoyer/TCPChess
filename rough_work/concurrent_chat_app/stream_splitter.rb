# frozen_string_literal: true

# This class receives a payload from the Client pool, splits each of the
# messages in the payload into their own "packets", and writes the packets onto
# an IO stream that is connected to the server. The order in which the packets
# are sent to the Server is randomized to simulate an arbitrary stream of data
# flowing into the Server from a Network.
class StreamSplitter
  def initialize(writer)
    @writer = writer
    @queue = Queue.new
  end

  def start
    @worker = Thread.new do
      begin
        loop do
          # blocking pop!
          msg = @queue.pop
          break if msg == :shutdown

          # simulate network delay
          sleep rand(0..0.2)
          @writer.write msg
          @writer.flush
        end
      ensure
        @writer.flush
        @writer.close
      end
    end
  end

  def shutdown
    @worker.join
    puts 'StreamSplitter: Done'
  end

  # This object receives:
  # { :method => :message, :params => { 'NUM' => 'TEXT', ... } }
  def receive_notification(payload)
    serialized_messages = serialize(payload)
    enqueue(serialized_messages)
  end

  def signal_shutdown
    @queue << :shutdown
  end

  private

  def enqueue(messages)
    messages.each { |msg| @queue << msg }
  end

  # Returns array of strings
  # @payload data is converted to an array of strings, like so:
  # ["1@msg msg msg", "2@msg msg msg", ...]
  # Use \r\n\r\n as a delimiter
  def serialize(payload)
    payload[:params].map do |client_no, msg|
      "#{client_no}@#{msg}\r\n\r\n"
    end.shuffle!
  end
end
