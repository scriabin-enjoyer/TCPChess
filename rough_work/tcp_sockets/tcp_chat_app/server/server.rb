# frozen_string_literal: true

require 'socket'

module TCPChatApp
  # Implements a single-threaded, event-driven server that maintains a list of
  # chatrooms within which clients can send each other messages.
  class Server
    SERVER_PORT = 2211
    SERVER_HOST = '0.0.0.0'
    MAX_BACKLOG_SIZE = 100
    LOG_FILE = $stdout

    def initialize
      @waiting_queue = []
      @listening_socket = Socket.new(:INET, :STREAM).then do |sock|
        addr = Socket.pack_sockaddr_in(SERVER_PORT, SERVER_HOST)
        sock.bind addr
        sock.listen(MAX_BACKLOG_SIZE)
        sock
      end
      LOG_FILE.puts "{#{Time.now.utc}}: Server listening on #{SERVER_PORT} on all interfaces"
    end

    def run
      loop do
        # 1. Match people in the waiting queue, put them into a room
        # 2. select() for sockets
        # 3. Handle new connections
        # 4. Handle readable sockets
        # 5. Handle writable sockets
        read_ready, write_ready= IO.select([@listening_socket] + @peer_map.keys, @peer_map.keys)

        read_ready.each do |sock|
          if sock == @listening_socket
            # When client connects, they are put into a "waiting room" queue
            # when there are >= 2 people in the queue, will start to match them
          else
            # read
          end
        end
      end
    end
  end

end

module TCPChatApp
  # Wraps all Socket logic, connection handling, etc.
  class Connection
    def initialize

    end
  end
end
