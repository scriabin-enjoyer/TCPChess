# frozen_string_literal: true

require 'socket'

module TCPChatApp
  # Implements a single-threaded, event-driven server that maintains a list of
  # chatrooms within which clients can send each other messages.
  class Server
    SERVER_PORT = 2211
    SERVER_HOST = '0.0.0.0'
    MAX_BACKLOG_SIZE = 100
    LOG_STREAM = $stdout

    def initialize
      @listening_socket = Socket.new(:INET, :STREAM).then do |sock|
        addr = Socket.pack_sockaddr_in(SERVER_PORT, SERVER_HOST)
        sock.bind addr
        sock.listen(MAX_BACKLOG_SIZE)
        sock
      end
      LOG_STREAM.puts "Server listening on #{SERVER_PORT} on all interfaces"

      @peer_map = {}
    end

    def run
      raise NotImplementedError
      # PROGRAM FLOW:
      # - listen for incoming connections
      # - when a client connects, push them onto a queue
      # - when there are at least 2 people in the queue, pop the Q twice and 
      # put them in a chatroom
      # - execute 
    end
  end

end
