# frozen_string_literal: true

# rubocop:disable Lint/UselessAssignment
# rubocop:disable Lint/RedundantCopDisableDirective
# rubocop:disable Lint/MissingCopEnableDirective
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/ClassLength
# rubocop:disable Naming/MethodParameterName
# rubocop:disable Naming/AccessorMethodName
# rubocop:disable Style/Documentation
# rubocop:disable Style/TrailingCommaInHashLiteral

require 'socket'

module TCPChatApp
  SERVER_PORT = 2211
  SERVER_HOST = '0.0.0.0'
  MAX_BACKLOG_SIZE = 100
  MSG_TYPES = {
    register_req: 0x01,    # Client -> Server
    register_rcpt: 0x02,   # Server -> Client
    broadcast_req: 0x03,   # Client -> Server
    broadcast_rcpt: 0x04,  # Server -> Client
    direct_req: 0x05,      # Client -> Server
    direct_rcpt: 0x06,     # Server -> Client
    list: 0x07,            # Client -> Server
    list_response: 0x8,    # Server -> Client
    exit: 0x9,             # Client -> Server
  }.freeze

  # Implements a single-threaded server that maintains a list of connected
  # clients. The Server will periodically check each client to see if they have
  # sent any messages, and relay those messages according to a simple protocol.
  # Clients may choose to broadcast a message or send a message to another
  # specified client. Clients may query the server for a list of currently
  # connected clients. When a client is done chatting with others, they can
  # send an exit message to the server, and the server will take care of
  # cleaning up any state that the connection was using.
  class Server
    def initialize
      # Setup Data Structures
      @active_clients = {}
      @registered_clients = {}
      # Setup Listener
      @listening_socket = Socket.new(:INET, :STREAM)
      @local_addr = Socket.pack_sockaddr_in(SERVER_PORT, SERVER_HOST)
      @listening_socket.bind(@local_addr)
      @listening_socket.listen(MAX_BACKLOG_SIZE)
    end

    def start
      loop do
        client, client_addr = @listening_socket.accept_nonblock
        # Accept
        # register
        # broadcast
        # DMs
      end
    rescue => e
    end

    def parse_message
      raise NotImplementedError
    end

    def register_client
      raise NotImplementedError
    end

    def remove_client
      raise NotImplementedError
    end

    def broadcast
      raise NotImplementedError
    end

    def relay_dm
      raise NotImplementedError
    end
  end
end
