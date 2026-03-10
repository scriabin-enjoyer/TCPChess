# frozen_string_literal: true

# Server:
# Spawn some threads to handle to following
#   - Listen for streamed data packets on reader;
#   - If datagram is a message from a client, just write to stdout
class Server
  def initialize(reader)
    @reader = reader
  end

  def start
    @worker = Thread.new do
      begin
        loop do
          msg = @reader.gets("\r\n\r\n", chomp: true)
          break if msg.nil? # EOF

          puts msg.sub!('@', ': ')
        end
      ensure
        @reader.close
      end
    end
  end

  def shutdown
    @worker.join
    puts 'Server: Done'
  end
end
