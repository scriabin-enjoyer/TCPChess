# frozen_string_literal: true

# rubocop:disable Lint/MissingCopEnableDirective
# rubocop:disable Lint/RedundantCopDisableDirective
# rubocop:disable Lint/UselessAssignment
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/ClassLength
# rubocop:disable Naming/MethodParameterName
# rubocop:disable Naming/AccessorMethodName

require 'socket'

# IDEA2: Chatrooms
# Server:
#   - Receives up to 1000 clients into a queue
#   - matches each client with next in queue
#   - puts them into a private chatroom
#   - each paired client can send and receive messages from each other
#   - messages are relayed through the server
#   - the server processes the messages concurrently via nonblocking io
#
module ChatRooms
  class ClientSocket
  end

  # Listening server that matches clients with eachother
  class MyServer
    LISTENING_PORT = 2211
    MAX_ROOMS = 1000
    MAX_CLIENTS = 2000

    def initialize
      @server = TCPServer.new(LISTENING_PORT)
    end

    def start
    end

    # SERVER LOOP:
    # - check for new connection requests on listening socket
    # - If there are any new sockets, and there is room for them, append them to clients list
    #   - maybe queue the new clients in another "waiting room" queue (after handshaking them), and then append them to the clients queue after each server loop
    #   - maybe use accept_nonblock for this, rescue errors for control flow lol, or maybe not
    # - Next, check the rest of the sockets (IO.select) to see if they are readable
    #   - For all readable sockets, in order, broadcast the messages
    # - Perhaps maintain an authoritative event log
    # - Trouble with the loop:
    #   - Do we
  end
end
