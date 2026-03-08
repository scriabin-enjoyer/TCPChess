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
      @clients = Array.new
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
        # before calling select, implement monitor_for_reading? and
        # monitor_for_writing? on my Connection class, then generate the
        # read_sockets, write_sockets for IO.select. The below is just here
        # temporarily
        read_ready, = IO.select([@listening_socket] + @clients, @clients)
        read_ready.each { |conn| handle_readables(conn) }
      end
    end

    # NOTE: WIP
    def handle_readables(connection)
      if connection == @listening_socket
        # In the very unlikely case that the listening_socket starts filling up
        # its backlog, we should pop the queue until its empty
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
  end

  # Wraps all Socket logic, connection handling, etc.
  # Input: Maintains its own personal buffer to receive data from the Transport layer
  # Output: Provides methods to send data
  # Connection Lifecycle: Startup, shutdown, etc.
  # Protocol Bridge: Should handle streaming data from transport layer and also
  # message boundaries for partial reads
  class Connection
    def initialize(socket)
      raise NotImplementedError
    end

    def to_io
      raise NotImplementedError
    end
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
