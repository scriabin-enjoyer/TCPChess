# frozen_string_literal: true

require 'socket'

require_relative 'connection'
require_relative 'accept_handler'
require_relative 'connection_handler'

module TCPChatApp
  # Implements a single-threaded, event-driven server that maintains a list of
  # chatrooms within which clients can send each other messages.
  class Server
    SERVER_PORT = 2211
    SERVER_HOST = '0.0.0.0'
    MAX_BACKLOG_SIZE = 100
    LOG_FILE = $stdout
    MAX_CLIENTS = 1000

    def initialize
      @active_client_handles = {}
      @connection_handler = ConnectionHandler.new
      @accept_handler = AcceptHandler.new(@connection_handler)
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
        to_read = @active_client_handles.values.select(&:monitor_for_reading?) + @listening_socket
        to_write = @active_client_handles.values.select(&:monitor_for_writing?)

        readables, writables = IO.select(to_read, to_write)
        readables.each { |conn| handle_readable(conn) }
        writables.each { |conn| handle_writable(conn) }
      end
    end

    def handle_readable(connection)
      if connection == @listening_socket
        loop do
          new_client = connection.accept_nonblock(exception: false)
          break if new_client == :wait_readable

          @active_client_handles[new_client.fileno] = Connection.new(new_client)
          @accept_handler.intake(new_client)
        end
      else
        @connection_handler.process_readable(connection)
      end
    end

    def handle_writable(connection)
      raise NotImplementedError
    end
  end
end
