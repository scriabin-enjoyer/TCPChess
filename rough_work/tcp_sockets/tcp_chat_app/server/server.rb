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
      @intake_queue = IntakeQueue.new
      @clients = []
      # Expose socket creation process just to be explicit
      @listening_socket = Socket.new(:INET, :STREAM).then do |sock|
        addr = Socket.pack_sockaddr_in(SERVER_PORT, SERVER_HOST)
        sock.bind addr
        sock.listen(MAX_BACKLOG_SIZE)
        sock
      end
      LOG_FILE.puts "{#{Time.now.utc}}: Server listening on #{SERVER_PORT} on all interfaces"
    end

    # NOTE: WIP
    def run
      loop do
        # TODO: Need to also define hooks/callbacks for connections to register
        # their interest in being writable — in the case that the server needs
        # to relay messages, or ping clients, etc.
        readable, writable = IO.select([@listening_socket] + @clients, @clients)
        readable.each { |conn| handle_readable(conn) }
        writable.each { |conn| handle_writable(conn) }
      end
    end

    # NOTE: WIP
    def handle_readable(connection)
      if connection == @listening_socket
        # In the very unlikely case that the listening_socket starts filling up
        # its backlog, we should pop the backlog until its empty
        while (new_client = connection.accept_nonblock(exception: false)) != :wait_readable
          @intake_queue.process new_client
        end
      else
        handle_client_event(connection)
      end
    end

    # NOTE: WIP
    def handle_client_event(connection)
      raise NotImplementedError
    end

    def handle_writable(connection)
      raise NotImplementedError
    end
  end

  # Represents a connection between the Client and this Server
  # Wraps all Socket logic, connection handling, etc.
  # Manages all low-level socket input, output, and life-cycle
  # Acts as a protocol bridge as well, should handle streaming data from
  # transport layer and reconstructing full application-level messages,
  # especially when the message boundaries are not preserved with partial reads
  class Connection
    def initialize(socket)
      raise NotImplementedError
    end

    def to_io
      raise NotImplementedError
    end
  end

  # Represents a chat room between 2 clients (Connection objects)
  class ChatRoom
  end

  # Represents 
  class RoomManager
  end

  # Processes newly accepted client sockets and matches them with another
  # waiting client on a FIFO basis. 
  class IntakeQueue
    def initialize
      @queue = []
    end

    def process(conn)
      @queue << conn
    end

    def match
      raise NotImplementedError
    end

    def ready_to_match
      raise NotImplementedError
    end
  end
end
