# frozen_string_literal: true

require 'socket'

require_relative 'connection'
require_relative 'accept_handler'
require_relative 'connection_handler'

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
  # active socket connections, and waits for read/write events from the sockets
  # and delegates these events to appropriate handelrs.
  class Server
    SERVER_PORT = 2211
    SERVER_HOST = '127.0.0.1'
    MAX_BACKLOG_SIZE = 100
    # TODO: HANDLE MAX CLIENTS
    MAX_CLIENTS = 1000

    def initialize
      @connection_handles = {}

      trap(:INT) do
        @connection_handles.each_value(&:close)
        log :note, "Closed all client connections. Shutting Down."
        exit
      end

      # Explicitly setup server socket
      @control_socket = Socket.new(:INET, :STREAM).then do |sock|
        addr = Socket.pack_sockaddr_in(SERVER_PORT, SERVER_HOST)
        sock.bind addr
        sock.listen(MAX_BACKLOG_SIZE)
        sock
      end
      log :note, "Listening on port #{SERVER_PORT} on #{SERVER_HOST}"
    end

    def run
      loop do
        to_read, to_write = query_io_interested_clients

        readables, writables = IO.select(to_read + [@control_socket], to_write)

        readables.each { |conn| handle_readable(conn) }
        writables.each { |conn| handle_writable(conn) }
      end
    end

    def query_io_interested_clients
      to_read = @connection_handles.values.select(&:monitor_for_reading?)
      to_write = @connection_handles.values.select(&:monitor_for_writing?)
      [to_read, to_write]
    end

    def handle_readable(connection)
      if connection == @control_socket
        loop do
          new_client, addr = connection.accept_nonblock(exception: false)
          return if new_client == :wait_readable

          @connection_handles[new_client.fileno] = Connection.new(new_client)
          @accept_handler.intake(new_client)

          log :note, "Client Processed: #{addr}"
        end
      elsif connection.closed?
        @connection_handles.delete(connection.fd)
      else
        @connection_handler.process_readable(connection)
      end
    end

    def handle_writable(connection)
      connection.on_writable
    end
  end
end

TCPChatAppServer::Server.new.run
