# frozen_string_literal: true

require 'socket'

require_relative 'connection'

LOG_FILE = $stdout

def log(type, message)
  if type == :data
    p message
  else
    LOG_FILE.puts "\n[#{type.upcase}][#{Time.now}] Server: #{message}\n"
  end
end

module TCPChatAppServer
  # Implements a single-threaded, event-driven server that maintains a list of
  # active socket connections, waits for read/write events from the sockets,
  # and delegates these events to appropriate handelrs.
  class Server
    SERVER_PORT = 2211
    SERVER_HOST = '127.0.0.1'
    MAX_BACKLOG_SIZE = 100
    # TODO: HANDLE MAX CLIENTS
    MAX_CLIENTS = 1000

    def initialize
      @connection_handles = {}
      @shutdown = false

      trap(:INT) do
        @shutdown = true
      end

      # Explicitly setup listening socket
      @control_socket = Socket.new(:INET, :STREAM).tap do |sock|
        # reuse the server port if we need to restart the server
        sock.setsockopt(:SOCKET, :REUSEADDR, true)

        # Max message size is 257 bytes -> MTU usually 1500
        sock.setsockopt(:IPPROTO_TCP, :NODELAY, true)

        # Setup Server socket
        addr = Socket.pack_sockaddr_in(SERVER_PORT, SERVER_HOST)
        sock.bind addr
        sock.listen(MAX_BACKLOG_SIZE)
      end
      log :note, "Listening on port #{SERVER_PORT} on interface #{SERVER_HOST}"
    end

    def run
      loop do
        break if @shutdown

        to_read, to_write = io_interested_clients
        readables, writables = IO.select(to_read + [@control_socket], to_write)
        readables.each { |conn| handle_readable(conn) }
        writables.each { |conn| handle_writable(conn) }
      end

      @connection_handles.each_value do |conn|
        conn.close
      rescue StandardError
        next
      end
      log :note, "Closed all client connections. Shutting Down."
      exit
    end

    def io_interested_clients
      to_read = @connection_handles.values.select(&:monitor_for_reading?)
      to_write = @connection_handles.values.select(&:monitor_for_writing?)
      [to_read, to_write]
    end

    def handle_readable(connection)
      if connection == @control_socket
        # Process and flush all clients trying to connect
        loop do
          client_socket, = @control_socket.accept_nonblock(exception: false)
          break if client_socket == :wait_readable

          # NOTE: Remember to set binmode on the client socket in Connection
          # initialize
          # NOTE: Rememebr to set TCP NODELAY to true on client connection
          new_connection = Connection.new(client_socket)
          @connection_handles[new_connection.fileno] = new_connection
          new_connection.on_connect
        end
      elsif connection.closed?
        # NOTE: Remember to properly handle cleaning up this connection from
        # the entire server
        connection.teardown
        @connection_handles.delete(connection.fileno)
      else
        # Main work done here. This callback cascades through the entire server
        connection.on_readable
      end
    end

    def handle_writable(connection)
      # This should just flush write queue for the connection
      connection.on_writable
    end
  end
end

# TCPChatAppServer::Server.new.run
