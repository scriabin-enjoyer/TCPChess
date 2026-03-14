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

module TCPChatApp
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
      @active_client_handles = {}
      @connection_handler = ConnectionHandler.new
      @accept_handler = AcceptHandler.new(@connection_handler)

      trap(:INT) do
        @active_client_handles.each_value(&:close)
        log :note, "Closed all client connections. Shutting Down."
        exit
      end

      # Explicitly setup server socket
      @listening_socket = Socket.new(:INET, :STREAM).then do |sock|
        addr = Socket.pack_sockaddr_in(SERVER_PORT, SERVER_HOST)
        sock.bind addr
        sock.listen(MAX_BACKLOG_SIZE)
        sock
      end
      log :note, "Listening on port #{SERVER_PORT} on #{SERVER_HOST}"
    end

    def run
      loop do
        # register connections that are interested in io operations
        to_read = @active_client_handles.values.select(&:monitor_for_reading?)
        to_write = @active_client_handles.values.select(&:monitor_for_writing?)

        log :note, "#{to_read.size} readables, #{to_write.size} writables"

        # handle client events
        readables, writables = IO.select(to_read + [@listening_socket], to_write)

        readables.each { |conn| handle_readable(conn) }
        writables.each { |conn| handle_writable(conn) }

        # register newly connected clients
        register_new_rooms
      end
    end

    def handle_readable(connection)
      if connection == @listening_socket
        loop do
          log :note, "Accepting new clients"

          new_client, addr = connection.accept_nonblock(exception: false)
          if new_client == :wait_readable
            log :note, "Listening Socket no longer readable, breaking loop"
            return
          end

          log :note, "Accepted new client #{new_client}"

          @active_client_handles[new_client.fileno] = Connection.new(new_client)
          @accept_handler.intake(new_client)

          log :note, "Client Processed: #{addr}"
        end
      else
        @connection_handler.process_readable(connection)
      end
    end

    def handle_writable(connection)
      raise NotImplementedError
    end

    def register_new_clients
      @connection_handler.process_new_chatrooms
    end
  end
end

TCPChatApp::Server.new.run
