# frozen_string_literal: true

require 'socket'
require_relative '../logger'
require_relative 'connection'

module MyGameServer
  # Implements a single-threaded, event-driven server that maintains a list of
  # active socket connections, waits for read/write events from the sockets,
  # and invokes appropriate callbacks on these connections. The callbacks
  # should emit events to appropriate handlers.
  module Server
    class Server
      SERVER_PORT = 2211
      SERVER_HOST = '127.0.0.1'
      MAX_BACKLOG_SIZE = 100
      MAX_CLIENTS = 1000

      def initialize
        @connection_handles = {}
        @to_close = []
        @shutdown = false

        trap(:INT) do
          # @shutdown = true
          shutdown_server
        end

        @control_socket = Socket.new(:INET, :STREAM).tap do |sock|
          sock.setsockopt(:SOCKET, :REUSEADDR, true)
          sock.setsockopt(:TCP, :NODELAY, true)
          addr = Socket.pack_sockaddr_in(SERVER_PORT, SERVER_HOST)
          sock.bind addr
          sock.listen(MAX_BACKLOG_SIZE)
        end
        log :server, "Listening on port #{SERVER_PORT} on interface #{SERVER_HOST}"
      end

      def run
        oopsies = 0
        skill_issue = 10

        loop do
          break if @shutdown

          to_read, to_write = io_interested_clients
          readables, writables = IO.select(to_read + [@control_socket], to_write, nil, 10)
          readables&.each { |conn| handle_readable(conn) }
          writables&.each { |conn| handle_writable(conn) }
          remove_dead_conns
        rescue => e
          log :server, "Something raised! #{e.class}\n#{e.full_message}"
          oopsies += 1
          break if oopsies > skill_issue

          next
        end

        shutdown_server
      end

      def io_interested_clients
        to_read = @connection_handles.values.select(&:monitor_for_reading?)
        to_write = @connection_handles.values.select(&:monitor_for_writing?)
        [to_read, to_write]
      end

      def handle_readable(connection)
        if connection == @control_socket
          loop do
            client_socket, = @control_socket.accept_nonblock(exception: false)
            break if client_socket == :wait_readable

            if @connection_handles.size >= MAX_CLIENTS
              client_socket.close
              next
            end

            new_connection = Connection.new(client_socket)
            @connection_handles[new_connection.fileno] = new_connection
            new_connection.on_connect
          end
        else
          connection.on_readable
        end
      end

      def handle_writable(connection)
        connection.on_writable
      end

      def remove_dead_conns
        while (dead_conn = @to_close.pop)
          dead_conn.teardown
          @connection_handles.delete dead_conn.fileno
        end
      end

      def shutdown_server
        @connection_handles.each_value do |conn|
          conn.close
        rescue StandardError
          next
        end
        log :server, "Closed all client connections. Shutting Down."
        exit
      end
    end
  end
end
